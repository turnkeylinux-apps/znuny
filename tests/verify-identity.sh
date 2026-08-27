#!/bin/bash
set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
historical_changelog_line=$(awk '/^turnkey-otrs-18\.0 / {print NR; exit}' \
    "$repo_root/changelog")

fail() {
    printf 'identity verification failed: %s\n' "$*" >&2
    exit 1
}

allowed_otrs_hit() {
    local path=$1 line=$2 value=$3

    case "$path" in
        changelog)
            [[ $line =~ ^[0-9]+$ ]] && ((line >= historical_changelog_line)) && return 0
            [[ $value =~ OTRS-compatible ]] && return 0
            ;;
        README.rst)
            [[ $value =~ \(\(OTRS\)\)[[:space:]]Community[[:space:]]Edition|commercial[[:space:]]OTRS|OTRS[[:space:]]product[[:space:]]and[[:space:]]is[[:space:]]not[[:space:]]endorsed|OTRS-compatible ]] && return 0
            ;;
        docs/v19.0-testing.md)
            [[ $value =~ commercial[[:space:]]OTRS|OTRS-compatible|v18[[:space:]]OTRS-appliance|under[[:space:]]the[[:space:]]\`otrs\`[[:space:]]slug|/otrs|otrs2|otrs\.Console\.pl|[[:space:]]otrs[[:space:]]Unix ]] && return 0
            ;;
        docs/assets.md)
            [[ $value =~ commercial[[:space:]]OTRS|OTRS-branded ]] && return 0
            ;;
        Makefile)
            [[ $value == 'BACKPORTS_PINS=otrs' ]] && return 0
            ;;
        conf.d/main|overlay/etc/otrs/*|overlay/pkginfo.info)
            return 0
            ;;
        overlay/usr/lib/inithooks/bin/znuny.py)
            [[ $value =~ /usr/share/otrs|otrs\.Console\.pl|\'otrs\' ]] && return 0
            ;;
        overlay/usr/lib/inithooks/firstboot.d/20regen-znuny-secrets)
            [[ $value =~ otrs2|/etc/otrs|--user=otrs ]] && return 0
            ;;
        overlay/usr/local/sbin/turnkey-znuny-update)
            [[ $value =~ otrs2|/usr/share/otrs|runuser[[:space:]]-u[[:space:]]otrs|otrs\.Console\.pl|otrs\.Daemon\.pl ]] && return 0
            ;;
        overlay/var/www/index.cgi)
            [[ $value =~ /otrs/(login|customer)\.pl ]] && return 0
            ;;
        tests/v19.sh)
            [[ $value =~ /usr/share/otrs|/run/otrs|/otrs/index\.pl|/etc/cron\.d/otrs2|otrs\.Console\.pl|otrs\.Daemon\.pl|package[=[:space:]]otrs2|source:Package|dpkg-query.*otrs2|runuser[[:space:]]-u[[:space:]]otrs|mysql.*otrs|[[:space:]]otrs[[:space:]]|turnkey-znuny-19\.0 ]] && return 0
            [[ $value =~ grep.*TurnKey[[:space:]]OTRS|fail.*stale[[:space:]]TurnKey[[:space:]]OTRS ]] && return 0
            ;;
    esac

    return 1
}

run_self_test() {
    allowed_otrs_hit conf.d/main 1 'DB_NAME=otrs' || fail 'runtime database allowlist rejected'
    allowed_otrs_hit overlay/etc/otrs/apache.conf 1 '<Location /otrs>' ||
        fail 'package path allowlist rejected'
    allowed_otrs_hit overlay/usr/lib/inithooks/bin/znuny.py 1 \
        "'/usr/share/otrs/bin/otrs.Console.pl'" || fail 'console allowlist rejected'
    allowed_otrs_hit overlay/var/www/index.cgi 1 \
        'href="https://host/otrs/login.pl"' || fail 'internal route allowlist rejected'
    allowed_otrs_hit README.rst 1 'former ((OTRS)) Community Edition code line' ||
        fail 'compatibility explanation rejected'
    allowed_otrs_hit changelog "$((historical_changelog_line + 1))" \
        'historical OTRS entry' || fail 'historical changelog rejected'

    ! allowed_otrs_hit README.rst 1 'TurnKey OTRS appliance' ||
        fail 'stale README branding was allowed'
    ! allowed_otrs_hit overlay/var/www/index.cgi 1 '<h1>TurnKey OTRS</h1>' ||
        fail 'stale landing branding was allowed'
    ! allowed_otrs_hit overlay/usr/lib/inithooks/bin/znuny.py 1 'OTRS Password' ||
        fail 'stale prompt branding was allowed'
    ! allowed_otrs_hit overlay/usr/local/sbin/turnkey-znuny-update 1 \
        'turnkey-otrs-update --check' || fail 'stale updater branding was allowed'
    ! allowed_otrs_hit docs/v19.0-testing.md 1 'OTRS v19 testing' ||
        fail 'stale test-report branding was allowed'
    ! allowed_otrs_hit arbitrary.txt 1 'otrs' || fail 'unknown OTRS hit was allowed'

    echo 'identity self-test: PASS'
}

if [[ ${1:-} == --self-test ]]; then
    [[ $# == 1 ]] || fail 'usage: verify-identity.sh [--self-test]'
    run_self_test
    exit 0
fi
[[ $# == 0 ]] || fail 'usage: verify-identity.sh [--self-test]'

[[ $(basename "$repo_root") == znuny ]] || fail 'repository directory is not named znuny'
[[ $(git -C "$repo_root" branch --show-current) == wish-znuny-v19-trixie ]] ||
    fail 'unexpected topic branch'
git -C "$repo_root" merge-base --is-ancestor \
    0f0475b50a87eab992a8cf488245812db436e71d HEAD || fail 'seed commit is not an ancestor'
for excluded in \
    dd46748fabc21e2d054924302cf610c96367a630 \
    9225cca7a261f0b0b348c62f048848eb73302a15 \
    46094815f26d8bc1b3712675fd0347285892d33c; do
    ! git -C "$repo_root" merge-base --is-ancestor "$excluded" HEAD ||
        fail "OTRS-only blocker commit is an ancestor: $excluded"
done
[[ -z $(git -C "$repo_root" remote) ]] || fail 'a git remote is configured'

grep -Fxq 'Znuny - Open Source Service Desk' "$repo_root/README.rst" ||
    fail 'README title is not Znuny'
grep -Fxq 'turnkey-znuny-19.0 (1) turnkey; urgency=low' "$repo_root/changelog" ||
    fail 'v19 changelog identity is not turnkey-znuny-19.0'
grep -Fxq 'CREDIT_ANCHORTEXT = Znuny Appliance' "$repo_root/Makefile" ||
    fail 'credit identity is not Znuny'
grep -Fxq 'NONFREE = yes' "$repo_root/Makefile" ||
    fail 'Debian stable non-free component is not enabled for package otrs2'
grep -Fq '<title>TurnKey Znuny</title>' "$repo_root/overlay/var/www/index.cgi" ||
    fail 'landing title is not Znuny'
grep -Fq 'https://www.turnkeylinux.org/znuny' "$repo_root/overlay/var/www/index.cgi" ||
    fail 'landing release link is not Znuny'

for required in \
    overlay/usr/lib/inithooks/bin/znuny.py \
    overlay/usr/lib/inithooks/firstboot.d/20regen-znuny-secrets \
    overlay/usr/lib/inithooks/firstboot.d/40znuny \
    overlay/usr/local/sbin/turnkey-znuny-update \
    overlay/var/www/images/znuny.png; do
    [[ -e $repo_root/$required ]] || fail "renamed path is missing: $required"
done
for stale in \
    overlay/usr/lib/inithooks/bin/otrs.py \
    overlay/usr/lib/inithooks/firstboot.d/20regen-otrs-secrets \
    overlay/usr/lib/inithooks/firstboot.d/40otrs \
    overlay/usr/local/sbin/turnkey-otrs-update \
    overlay/var/www/images/otrs.png; do
    [[ ! -e $repo_root/$stale ]] || fail "stale TurnKey-facing path remains: $stale"
done

mapfile -t art_files < <(find "$repo_root/.art" -maxdepth 1 -type f -printf '%f\n' | sort)
[[ ${#art_files[@]} == 1 && ${art_files[0]} == logo.png ]] ||
    fail 'undocumented historical screenshots or art remain'
cmp -s "$repo_root/.art/logo.png" "$repo_root/overlay/var/www/images/znuny.png" ||
    fail 'documented identical badge copies differ'
file "$repo_root/.art/logo.png" | grep -Fq 'PNG image data' || fail 'badge is not a PNG'

while IFS= read -r path; do
    [[ -e $repo_root/$path ]] || continue
    case "$path" in
        overlay/etc/otrs/*) ;;
        *) fail "non-allowlisted OTRS path remains: $path" ;;
    esac
done < <(git -C "$repo_root" ls-files --cached --others --exclude-standard |
    grep -i 'otrs' || true)

while IFS=: read -r path line value; do
    [[ -n $path ]] || continue
    allowed_otrs_hit "$path" "$line" "$value" ||
        fail "non-allowlisted OTRS identity at $path:$line: $value"
done < <(git -C "$repo_root" grep -nIi -E 'otrs' -- . \
    ':(exclude)tests/verify-identity.sh' || true)

run_self_test >/dev/null
echo 'Znuny identity verification: PASS'
