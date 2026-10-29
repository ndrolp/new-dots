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

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
