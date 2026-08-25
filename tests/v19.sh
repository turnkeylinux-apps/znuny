#!/bin/bash -e

set -o pipefail

SOURCE_RECORD=/usr/local/share/turnkey-otrs/source
CONSOLE=/usr/share/otrs/bin/otrs.Console.pl
UPDATER=/usr/local/sbin/turnkey-otrs-update
COOKIE_JAR=/run/otrs-v19-cookie.$$
QUEUE=Wave2Acceptance$$
SUBJECT="Wave 2 mail ticket $$"

cleanup() {
    rm -f "$COOKIE_JAR"
}
trap cleanup EXIT

otrs_console() {
    /usr/sbin/runuser -u otrs -- env LC_ALL=C.UTF-8 "$CONSOLE" "$@"
}

[ -s "$SOURCE_RECORD" ]
grep -qx 'package=otrs2' "$SOURCE_RECORD"
grep -qx 'repository=Debian 13 Trixie non-free' "$SOURCE_RECORD"
installed=$(dpkg-query -W -f='${Version}' otrs2)
dpkg --compare-versions "$installed" ge '6.5.15-2'
[ "$(awk -F= '$1 == "installed_version" {print $2}' "$SOURCE_RECORD")" = \
    "$installed" ]

for service in apache2 mariadb postfix cron; do
    systemctl is-active --quiet "$service"
done
mysql --batch --skip-column-names otrs \
    -e 'SELECT COUNT(*) FROM users' | grep -Eq '^[1-9][0-9]*$'
otrs_console Maint::Database::Check >/dev/null

login_page=$(curl -fkSs -c "$COOKIE_JAR" \
    https://127.0.0.1/otrs/index.pl)
grep -q 'name="User"' <<<"$login_page"
dashboard=$(curl -fkSs -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    https://127.0.0.1/otrs/index.pl \
    --data-urlencode 'Action=Login' \
    --data-urlencode 'RequestedURL=' \
    --data-urlencode 'Lang=en' \
    --data-urlencode 'TimeZoneOffset=0' \
    --data-urlencode 'User=root@localhost' \
    --data-urlencode "Password=${OTRS_TEST_PASSWORD:-turnkey}")
grep -Eq 'Action=Logout|AgentDashboard' <<<"$dashboard"
! grep -q 'Login failed!' <<<"$dashboard"

otrs_console Admin::Queue::Add --name "$QUEUE" --group users >/dev/null
otrs_console Admin::Queue::List | grep -F "$QUEUE" >/dev/null

printf '%s\n' \
    'From: Wave 2 Sender <wave2@example.invalid>' \
    'To: support@localhost' \
    "Subject: $SUBJECT" \
    "Message-ID: <wave2-$$@example.invalid>" \
    'Date: Tue, 25 Aug 2026 21:00:00 +0000' \
    'Content-Type: text/plain; charset=UTF-8' \
    '' \
    'This ticket proves the Znuny mail ingestion path.' |
    otrs_console Maint::PostMaster::Read --target-queue "$QUEUE" --untrusted \
    >/dev/null

ticket_id=$(mysql --batch --skip-column-names otrs \
    -e "SELECT id FROM ticket WHERE title='$SUBJECT' ORDER BY id DESC LIMIT 1")
case "$ticket_id" in
    ''|*[!0-9]*) exit 1 ;;
esac
mysql --batch --skip-column-names otrs \
    -e "SELECT q.name FROM ticket t JOIN queue q ON q.id=t.queue_id WHERE t.id=$ticket_id" |
    grep -Fx "$QUEUE" >/dev/null
ticket_dump=$(otrs_console Maint::Ticket::Dump --article-limit 1 "$ticket_id")
grep -F "$SUBJECT" <<<"$ticket_dump" >/dev/null
grep -F "$QUEUE" <<<"$ticket_dump" >/dev/null

install -d -o otrs -g www-data -m 0770 /run/otrs
/usr/sbin/runuser -u otrs -- /usr/share/otrs/bin/otrs.Daemon.pl start >/dev/null
/usr/sbin/runuser -u otrs -- /usr/share/otrs/bin/otrs.Daemon.pl status |
    grep -Fx 'Daemon running' >/dev/null
grep -q 'otrs.Daemon.pl start' /etc/cron.d/otrs2
otrs_console Maint::Daemon::List | grep -F SchedulerTaskWorker >/dev/null
otrs_console Maint::Email::MailQueue --list >/dev/null
postfix check
postconf -h inet_interfaces | grep -Eq 'loopback-only|localhost|127\.0\.0\.1|::1'

updater_check=$($UPDATER --check)
candidate=$(awk -F= '$1 == "candidate" {print $2}' <<<"$updater_check")
update_status=$(awk -F= '$1 == "status" {print $2}' <<<"$updater_check")
[ -n "$candidate" ]
case "$update_status" in
    up-to-date|update-available) ;;
    *) exit 1 ;;
esac
grep -qx 'apply=dry-run Debian signed package transaction' \
    < <($UPDATER --apply --dry-run)

echo 'package_source=Debian 13 Trixie non-free package otrs2 (Znuny 6.5 LTS)'
echo "installed_version=$installed"
echo 'runtime_checks=agent web login, queue create/read, mail ticket create/read, MariaDB, daemon, cron, Postfix, mail queue'
echo 'updater_command=turnkey-otrs-update --check; turnkey-otrs-update --apply --dry-run'
echo "updater_result=$update_status candidate $candidate; Debian signed dry-run transaction accepted"
echo 'updater_channel=Debian 13 stable packages for Znuny 6.5 LTS'
echo 'integrity_evidence=Debian archive signatures, apt candidate, installed dpkg version, and application database check'
