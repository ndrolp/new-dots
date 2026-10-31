#!/usr/bin/env bash
# Tests for starting Quickshell with start.sh, as Hyprland does at startup. It runs against the scratch
# HOME of the colorscheme changer's harness (colorschemes/colorscheme_changer_harness.sh), with every
# program a PATH shim, so no live session is touched.
# Run: common/.config/quickshell/tests/startup.sh [name filter]
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$QS_DIR/../../../colorschemes/colorscheme_changer_harness.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "${OUT:-}" | sed 's/^/    | /'
    return 1
}

# start_quickshell: runs start.sh from ~/.config/quickshell in a fresh scratch HOME laid out as stow
# leaves it, as an existing clone has it after a pull: no active or shown colorscheme yet (unless the
# test made one first with $ACTIVE_COLORSCHEME). Sets OUT, HOME_DIR and CALLS.
start_quickshell() {
    changer_home
    [[ -z "${ACTIVE_COLORSCHEME:-}" ]] || ln -s "$ACTIVE_COLORSCHEME" "$HOME_DIR/.dotfiles/colorschemes/active"
    [[ -z "${DEFAULT_COLORSCHEME:-}" ]] || echo "$DEFAULT_COLORSCHEME" >"$HOME_DIR/.dotfiles/colorschemes/default.txt"
    cp "$QS_DIR/start.sh" "$HOME_DIR/.dotfiles/common/.config/quickshell/"
    OUT="$(HOME="$HOME_DIR" PATH="$HOME_DIR/bin:$PATH" sh "$HOME_DIR/.config/quickshell/start.sh" 2>&1)" || true
}

colorschemes() { echo "$HOME_DIR/.dotfiles/colorschemes"; }

test_starting_without_active_or_shown_links_creates_them_from_the_default() {
    DEFAULT_COLORSCHEME=kanagawa start_quickshell
    [[ "$(readlink "$(colorschemes)/active")" == kanagawa ]] || fail "kanagawa is not active"
    [[ "$(readlink "$(colorschemes)/shown")" == kanagawa ]] || fail "kanagawa is not shown"
    [[ "$(readlink -f "$HOME_DIR/.config/quickshell/config/colors.json")" == "$(colorschemes)/kanagawa/quickshell/colors.json" ]] \
        || fail "Quickshell's colours do not lead to kanagawa's"
}

test_the_links_exist_before_quickshell_starts() {
    changer_home
    cp "$QS_DIR/start.sh" "$HOME_DIR/.dotfiles/common/.config/quickshell/"
    printf '#!/bin/sh\nreadlink -f "$HOME/.config/quickshell/config/colors.json" >>"$HOME/calls"\n' \
        >"$HOME_DIR/bin/quickshell"
    OUT="$(HOME="$HOME_DIR" PATH="$HOME_DIR/bin:$PATH" sh "$HOME_DIR/.config/quickshell/start.sh" 2>&1)" || true
    grep -qx "$(colorschemes)/everforestdark/quickshell/colors.json" "$CALLS" \
        || fail "Quickshell started before its colours led anywhere: $(cat "$CALLS")"
}

test_starting_leaves_an_active_colorscheme_alone() {
    ACTIVE_COLORSCHEME=nord start_quickshell
    [[ "$(readlink "$(colorschemes)/active")" == nord ]] || fail "the active colorscheme changed"
    [[ "$(readlink "$(colorschemes)/shown")" == nord ]] || fail "nord is not shown"
}

test_starting_drives_nothing_but_quickshell_and_gsettings() {
    start_quickshell
    [[ "$(cut -d' ' -f1 "$CALLS" | sort -u | tr '\n' ' ')" == "gsettings quickshell " ]] \
        || fail "calls: $(cat "$CALLS")"
}

test_quickshell_still_starts_when_the_links_cannot_be_created() {
    DEFAULT_COLORSCHEME=nosuch start_quickshell
    grep -q "^quickshell --path $HOME_DIR/.config/quickshell" "$CALLS" || fail "Quickshell was not started"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
