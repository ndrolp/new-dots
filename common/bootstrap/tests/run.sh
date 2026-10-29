#!/usr/bin/env bash
# Runs bootstrap.sh against a throwaway HOME. Needs no root and never touches the real home.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BOOTSTRAP="$REPO/bootstrap.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# Runs bootstrap in a fresh temp HOME from a cwd outside the repo.
# Sets OUT and STATUS; TEST_HOME stays for assertions.
run_bootstrap() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    STATUS=0
    OUT="$(cd "$TEST_HOME" && env HOME="$TEST_HOME" PATH="${EXTRA_PATH:+$EXTRA_PATH:}$PATH" bash "$BOOTSTRAP" "$@" 2>&1)" || STATUS=$?
}

test_help_lists_the_flags() {
    run_bootstrap --help
    [[ $STATUS -eq 0 ]] || fail "--help exited $STATUS"
    for flag in --host --minimal --stow-only --no-system --spicetify --help; do
        grep -q -- "$flag" <<<"$OUT" || fail "--help does not mention $flag"
    done
}

test_unknown_flag_exits_non_zero() {
    run_bootstrap --no-such-flag
    [[ $STATUS -ne 0 ]] || fail "unknown flag exited 0"
    grep -q -- "--no-such-flag" <<<"$OUT" || fail "error does not name the flag"
}

test_refuses_to_run_as_root() {
    EXTRA_PATH="$SCRATCH/fake-root"
    mkdir -p "$EXTRA_PATH"
    printf '#!/bin/sh\n[ "$1" = -u ] && echo 0 || /usr/bin/id "$@"\n' >"$EXTRA_PATH/id"
    chmod +x "$EXTRA_PATH/id"
    run_bootstrap --stow-only --host none
    [[ $STATUS -ne 0 ]] || fail "ran as root and exited 0"
    grep -qi "root" <<<"$OUT" || fail "error does not mention root"
    [[ -z "$(ls -A "$TEST_HOME")" ]] || fail "touched HOME before refusing: $(ls -A "$TEST_HOME")"
}

test_stow_only_links_common_from_outside_the_repo() {
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "--stow-only exited $STATUS"
    [[ -L "$TEST_HOME/.zshrc" ]] || fail ".zshrc is not a symlink"
    [[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$REPO/common/.zshrc" ]] || fail ".zshrc does not point into the repo"
    [[ ! -e "$TEST_HOME/bootstrap" ]] || fail "stowed the bootstrap dir"
}

test_stow_only_links_the_host_dir_when_it_exists() {
    run_bootstrap --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "--stow-only --host omelas exited $STATUS"
    [[ "$(readlink -f "$TEST_HOME/.config/hyprdynamicmonitors/config.toml")" == "$REPO/host-omelas/.config/hyprdynamicmonitors/config.toml" ]] \
        || fail "host-omelas was not stowed"
}

test_each_run_writes_a_log_and_prints_a_summary() {
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -qi "summary" <<<"$OUT" || fail "no summary printed"
    local logs=("$TEST_HOME"/.local/state/dotfiles/bootstrap-*.log)
    [[ -f "${logs[0]}" ]] || fail "no log under ~/.local/state/dotfiles"
    grep -qi "summary" "${logs[0]}" || fail "log does not hold the run's output"
}

test_a_failing_step_exits_non_zero_and_still_prints_the_summary() {
    run_bootstrap --stow-only --host no-such-host
    rm "$TEST_HOME/.zshrc" && echo "mine" >"$TEST_HOME/.zshrc"
    rm -rf "$TEST_HOME/.config"
    STATUS=0
    OUT="$(cd "$TEST_HOME" && HOME="$TEST_HOME" bash "$BOOTSTRAP" --stow-only --host no-such-host 2>&1)" || STATUS=$?
    [[ $STATUS -ne 0 ]] || fail "stow conflict exited 0"
    grep -q "Failed:" <<<"$OUT" || fail "summary does not list the failure"
    grep -q "step stow" <<<"$OUT" || fail "summary does not name the failed step"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
