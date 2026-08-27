#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
app_password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
source_record=/usr/local/share/turnkey-znuny/source
console=/usr/share/otrs/bin/otrs.Console.pl
daemon=/usr/share/otrs/bin/otrs.Daemon.pl
updater=/usr/local/sbin/turnkey-znuny-update
test_tmpdir=$(mktemp -d -t turnkey-znuny-v19.XXXXXXXX)
cookie_jar=$test_tmpdir/cookies
login_page=$test_tmpdir/login-page
dashboard=$test_tmpdir/dashboard
queue=Wave2ZnunyAcceptance$$
subject="Wave 2 Znuny mail ticket $$"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    find "$test_tmpdir" -depth -delete
}
trap cleanup EXIT HUP INT TERM

znuny_console() {
    /usr/sbin/runuser -u otrs -- env LC_ALL=C.UTF-8 "$console" "$@"
}

znuny_login() {
    rm -f "$cookie_jar"
    curl -fkSs -c "$cookie_jar" https://127.0.0.1/otrs/index.pl \
        >"$login_page"
    grep -q 'name="User"' "$login_page" || fail 'agent login form is absent'
    curl -fkSs -L -b "$cookie_jar" -c "$cookie_jar" \
        https://127.0.0.1/otrs/index.pl \
        --data-urlencode 'Action=Login' \
        --data-urlencode 'RequestedURL=' \
        --data-urlencode 'Lang=en' \
        --data-urlencode 'TimeZoneOffset=0' \
        --data-urlencode 'User=root@localhost' \
        --data-urlencode "Password=$app_password" >"$dashboard"
    grep -Eq 'Action=Logout|AgentDashboard' "$dashboard" ||
        fail 'authenticated Znuny dashboard was not returned'
    ! grep -q 'Login failed!' "$dashboard" || fail 'Znuny login failed'
}

test -s "$source_record" || fail 'Znuny source record is missing'
grep -qx 'package=otrs2' "$source_record" || fail 'binary package record changed'
grep -qx 'source_package=znuny' "$source_record" || fail 'source package record changed'
grep -qx 'repository=Debian 13 Trixie non-free' "$source_record" ||
    fail 'repository record changed'
grep -qx 'channel=Debian stable packages for Znuny 6.5 LTS' "$source_record" ||
    fail 'update channel record changed'

installed=$(dpkg-query -W -f='${Version}' otrs2)
source_package=$(dpkg-query -W -f='${source:Package}' otrs2)
test "$source_package" = znuny || fail "unexpected source package: $source_package"
dpkg --compare-versions "$installed" ge '6.5.15-2' ||
    fail "unexpected package version: $installed"
test "$(awk -F= '$1 == "installed_version" {print $2}' "$source_record")" = \
    "$installed" || fail 'source record does not match installed version'
grep -Fxq 'VERSION_CODENAME=trixie' /etc/os-release || fail 'not Debian Trixie'
grep -Eq '^turnkey-znuny-19\.0' /etc/turnkey_version ||
    fail 'appliance release identity is not turnkey-znuny-19.0'
grep -q '\[20regen-znuny-secrets\] successfully completed' /var/log/inithooks.log ||
    fail 'Znuny secret regeneration did not complete'
grep -q '\[40znuny\] successfully completed' /var/log/inithooks.log ||
    fail 'normal Znuny firstboot did not complete'

for service in apache2 mariadb postfix cron; do
    systemctl is-active --quiet "$service" || fail "$service is not active"
done
curl -fkSs https://127.0.0.1/ >"$test_tmpdir/landing"
grep -Fq 'TurnKey Znuny' "$test_tmpdir/landing" || fail 'Znuny landing identity is absent'
! grep -Fiq 'TurnKey OTRS' "$test_tmpdir/landing" || fail 'stale TurnKey OTRS landing identity remains'
mysql --batch --skip-column-names otrs \
    -e 'SELECT COUNT(*) FROM users' | grep -Eq '^[1-9][0-9]*$' ||
    fail 'Znuny users table is unavailable'
znuny_console Maint::Database::Check >/dev/null
znuny_login

znuny_console Admin::Queue::Add --name "$queue" --group users >/dev/null
znuny_console Admin::Queue::List | grep -F "$queue" >/dev/null ||
    fail 'created queue was not returned'

printf '%s\n' \
    'From: Wave 2 Sender <wave2@example.invalid>' \
    'To: support@localhost' \
    "Subject: $subject" \
    "Message-ID: <wave2-znuny-$$@example.invalid>" \
    'Date: Tue, 25 Aug 2026 21:00:00 +0000' \
    'Content-Type: text/plain; charset=UTF-8' \
    '' \
    'This ticket proves the Znuny mail ingestion path.' |
    znuny_console Maint::PostMaster::Read --target-queue "$queue" --untrusted \
        >/dev/null

ticket_id=$(mysql --batch --skip-column-names otrs \
    -e "SELECT id FROM ticket WHERE title='$subject' ORDER BY id DESC LIMIT 1")
[[ $ticket_id =~ ^[0-9]+$ ]] || fail 'mail-created ticket id is not numeric'
mysql --batch --skip-column-names otrs \
    -e "SELECT q.name FROM ticket t JOIN queue q ON q.id=t.queue_id WHERE t.id=$ticket_id" |
    grep -Fx "$queue" >/dev/null || fail 'ticket queue did not persist in MariaDB'
ticket_dump=$(znuny_console Maint::Ticket::Dump --article-limit 1 "$ticket_id")
grep -F "$subject" <<<"$ticket_dump" >/dev/null || fail 'ticket subject readback failed'
grep -F "$queue" <<<"$ticket_dump" >/dev/null || fail 'ticket queue readback failed'

install -d -o otrs -g www-data -m 0770 /run/otrs
if ! /usr/sbin/runuser -u otrs -- "$daemon" status 2>/dev/null |
        grep -Fx 'Daemon running' >/dev/null; then
    /usr/sbin/runuser -u otrs -- "$daemon" start >/dev/null
fi
/usr/sbin/runuser -u otrs -- "$daemon" status |
    grep -Fx 'Daemon running' >/dev/null || fail 'Znuny daemon is not running'
grep -q 'otrs.Daemon.pl start' /etc/cron.d/otrs2 || fail 'Znuny cron contract is absent'
znuny_console Maint::Daemon::List | grep -F SchedulerTaskWorker >/dev/null ||
    fail 'scheduler worker is absent'
znuny_console Maint::Email::MailQueue --list >/dev/null
postfix check
postconf -h inet_interfaces | grep -Eq 'loopback-only|localhost|127\.0\.0\.1|::1' ||
    fail 'Postfix is not loopback-bound'

systemctl restart mariadb apache2
systemctl is-active --quiet mariadb || fail 'MariaDB failed after restart'
systemctl is-active --quiet apache2 || fail 'Apache failed after restart'
znuny_console Maint::Database::Check >/dev/null
test "$(mysql --batch --skip-column-names otrs \
    -e "SELECT title FROM ticket WHERE id=$ticket_id")" = "$subject" ||
    fail 'ticket did not survive MariaDB restart'
znuny_login
/usr/sbin/runuser -u otrs -- "$daemon" stop --force >/dev/null 2>&1 || true
/usr/sbin/runuser -u otrs -- "$daemon" start >/dev/null
/usr/sbin/runuser -u otrs -- "$daemon" status |
    grep -Fx 'Daemon running' >/dev/null || fail 'Znuny daemon failed after restart'

updater_check=$($updater --check)
candidate=$(awk -F= '$1 == "candidate" {print $2}' <<<"$updater_check")
update_status=$(awk -F= '$1 == "status" {print $2}' <<<"$updater_check")
test -n "$candidate" || fail 'updater candidate is empty'
case "$update_status" in
    up-to-date|update-available) ;;
    *) fail "unexpected updater status: $update_status" ;;
esac
grep -qx 'apply=dry-run Debian signed package transaction' \
    < <($updater --apply --dry-run) || fail 'signed updater dry-run failed'

cat >"$result" <<EOF
package_source=Debian 13 Trixie non-free binary package otrs2 from source package znuny (Znuny 6.5 LTS)
installed_version=$installed
runtime_checks=normal firstboot; Znuny landing and authenticated agent login; queue create/read; mail ticket create/read; MariaDB persistence after restart; daemon restart; cron; Postfix; application mail queue
updater_command=turnkey-znuny-update --check; turnkey-znuny-update --apply --dry-run
updater_result=$update_status candidate $candidate; Debian signed dry-run transaction accepted
updater_channel=Debian 13 stable packages for Znuny 6.5 LTS
integrity_evidence=Debian archive signatures; source package znuny; apt candidate; installed dpkg version; application database check
EOF

echo 'PASS: Znuny identity, firstboot, service-desk workflow, persistence, jobs, mail, and updater'
