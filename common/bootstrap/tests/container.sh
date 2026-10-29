#!/usr/bin/env bash
# Tests for scripts/test-bootstrap. Needs Docker; each test starts a fresh archlinux container.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HARNESS="$REPO/scripts/test-bootstrap"
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | tail -40 | sed 's/^/    | /'
    return 1
}

run_harness() {
    STATUS=0
    OUT="$("$HARNESS" "$@" 2>&1)" || STATUS=$?
}

test_stow_only_passes_in_a_fresh_container() {
    run_harness --stow-only
    [[ $STATUS -eq 0 ]] || fail "test-bootstrap --stow-only exited $STATUS"
    grep -q "stow: common" <<<"$OUT" || fail "the bootstrap did not stow common"
}

test_extra_args_reach_the_bootstrap() {
    run_harness --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "stow: host-omelas" <<<"$OUT" || fail "--host omelas did not reach the bootstrap"
}

test_a_failing_bootstrap_fails_the_harness() {
    run_harness --no-such-flag
    [[ $STATUS -ne 0 ]] || fail "a bad flag exited 0"
    grep -q -- "Unknown option: --no-such-flag" <<<"$OUT" || fail "the bootstrap did not reject the flag"
}

harness_containers() { docker ps -aq --filter label=dotfiles.test-bootstrap=1 | sort; }

test_no_container_is_left_behind_after_a_pass_or_a_failure() {
    local before after
    before="$(harness_containers)"
    run_harness --stow-only
    run_harness --no-such-flag
    after="$(harness_containers)"
    [[ "$after" == "$before" ]] || fail "containers left behind: $(comm -13 <(echo "$before") <(echo "$after"))"
}

test_no_container_is_left_behind_when_interrupted() {
    local before after pid
    before="$(harness_containers)"
    "$HARNESS" --stow-only >/dev/null 2>&1 &
    pid=$!
    for _ in $(seq 50); do [[ "$(harness_containers)" != "$before" ]] && break; sleep 0.2; done
    kill -INT "$pid"
    wait "$pid" || true
    after="$(harness_containers)"
    OUT=""
    [[ "$after" == "$before" ]] || fail "containers left behind: $(comm -13 <(echo "$before") <(echo "$after"))"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
