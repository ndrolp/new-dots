#!/usr/bin/env bash
# Tests for services/monitor-notices.sh against a scratch folder: a backup is news once and no backup
# ever replaces another.
# Run: common/.config/quickshell/tests/monitor-notices.sh [name filter]
set -uo pipefail

NOTICES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/services/monitor-notices.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
FILTER="${1:-}"
failed=0

check() {
    if [ "$2" != "$3" ]; then
        echo "FAIL  $1: expected '$3', got '$2'"
        failed=1
    fi
}

scenario() {
    case "$1" in *"$FILTER"*) ;; *) return ;; esac
    rm -rf "${SCRATCH:?}"/*
    "$2"
}

saved="$SCRATCH/monitor-setups.json"

nothing_there() {
    check "the first line" "$(sh "$NOTICES" "$saved")" "readable"
}

a_bad_file_is_news_once() {
    echo one >"$saved.bad"
    check "the first time" "$(sh "$NOTICES" "$saved")" "unreadable"
    check "the backup" "$(cat "$saved.bad.told")" "one"
    check "the second time" "$(sh "$NOTICES" "$saved")" "readable"
}

an_earlier_backup_is_never_replaced() {
    echo one >"$saved.bad"
    sh "$NOTICES" "$saved" >/dev/null
    echo two >"$saved.bad"
    sh "$NOTICES" "$saved" >/dev/null
    echo three >"$saved.bad"
    sh "$NOTICES" "$saved" >/dev/null
    check "the first" "$(cat "$saved.bad.told")" "one"
    check "the second" "$(cat "$saved.bad.told.1")" "two"
    check "the third" "$(cat "$saved.bad.told.2")" "three"
}

every_waiting_backup_is_kept() {
    echo one >"$saved.bad"
    echo two >"$saved.bad.1"
    check "the first line" "$(sh "$NOTICES" "$saved")" "unreadable"
    check "the first" "$(cat "$saved.bad.told")" "one"
    check "the second" "$(cat "$saved.bad.told.1")" "two"
    check "nothing is left waiting" "$(sh "$NOTICES" "$saved")" "readable"
}

fallbacks_follow() {
    printf 'AOC\nPhilips\n' >"$saved.fallback"
    check "the monitors" "$(sh "$NOTICES" "$saved")" "readable
AOC
Philips"
}

spaces_in_the_path() {
    mkdir "$SCRATCH/a b"
    echo one >"$SCRATCH/a b/x.json.bad"
    check "the first line" "$(sh "$NOTICES" "$SCRATCH/a b/x.json")" "unreadable"
}

scenario "nothing there" nothing_there
scenario "a bad file is news once" a_bad_file_is_news_once
scenario "an earlier backup is never replaced" an_earlier_backup_is_never_replaced
scenario "every waiting backup is kept" every_waiting_backup_is_kept
scenario "fallbacks follow" fallbacks_follow
scenario "spaces in the path" spaces_in_the_path

[ "$failed" = 0 ] && echo "passed"
exit "$failed"
