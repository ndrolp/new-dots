#!/usr/bin/env bash
# Tests for the colorscheme step: bootstrap makes the default colorscheme active when no colorscheme is.
# Runs against copies of the repo; never touches the real home or the repo's own active link.
# Run: common/bootstrap/tests/colorscheme.sh [name filter]
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# dotfiles_copy: a copy of the repo's colorschemes, with no active colorscheme, in a scratch dotfiles
# folder. Sets DOTFILES.
dotfiles_copy() {
    DOTFILES="$(mktemp -d "$SCRATCH/dotfiles.XXXX")"
    cp -r "$REPO/colorschemes" "$DOTFILES/colorschemes"
    rm -f "$DOTFILES/colorschemes/active"
}

# run_colorscheme_step: runs steps/colorscheme.sh alone against $DOTFILES. Sets OUT and STATUS.
run_colorscheme_step() {
    STATUS=0
    OUT="$(env HOME="$(mktemp -d "$SCRATCH/home.XXXX")" DOTFILES_DIR="$DOTFILES" \
        bash "$REPO/common/bootstrap/steps/colorscheme.sh" 2>&1)" || STATUS=$?
}

# run_bootstrap_with_stub_steps <args>...: runs bootstrap.sh from a copy of the repo whose steps only log
# their name to $CALLS, so the test sees which steps a flag selects.
run_bootstrap_with_stub_steps() {
    local copy step
    copy="$(mktemp -d "$SCRATCH/repo.XXXX")"
    mkdir -p "$copy/common/bootstrap/steps"
    cp "$REPO/bootstrap.sh" "$copy/"
    cp "$REPO/common/bootstrap/lib.sh" "$copy/common/bootstrap/"
    for step in "$REPO"/common/bootstrap/steps/*.sh; do
        printf 'echo "step %s" >>"$CALLS"\n' "$(basename "$step" .sh)" >"$copy/common/bootstrap/steps/${step##*/}"
    done
    CALLS="$copy.calls"
    : >"$CALLS"
    STATUS=0
    OUT="$(env HOME="$(mktemp -d "$SCRATCH/home.XXXX")" CALLS="$CALLS" bash "$copy/bootstrap.sh" --host none "$@" 2>&1)" \
        || STATUS=$?
}

test_without_an_active_colorscheme_the_default_one_becomes_active() {
    dotfiles_copy
    echo kanagawa >"$DOTFILES/colorschemes/default.txt"
    run_colorscheme_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(readlink "$DOTFILES/colorschemes/active")" == kanagawa ]] || fail "kanagawa is not active"
}

test_an_active_colorscheme_is_left_alone() {
    dotfiles_copy
    ln -s nord "$DOTFILES/colorschemes/active"
    run_colorscheme_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(readlink "$DOTFILES/colorschemes/active")" == nord ]] || fail "the active colorscheme changed"
}

test_a_full_run_sets_up_the_colorscheme() {
    run_bootstrap_with_stub_steps
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step colorscheme$" "$CALLS" || fail "colorscheme did not run"
}

test_a_stow_only_run_sets_up_the_colorscheme() {
    run_bootstrap_with_stub_steps --stow-only
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step colorscheme$" "$CALLS" || fail "colorscheme did not run"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
