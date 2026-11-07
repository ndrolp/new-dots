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
    run_start_sh
}

# run_start_sh: runs start.sh with a runtime directory of its own, $HOME_DIR/run. Sets OUT.
run_start_sh() {
    mkdir -p "$HOME_DIR/run"
    OUT="$(HOME="$HOME_DIR" PATH="$HOME_DIR/bin:$PATH" XDG_RUNTIME_DIR="$HOME_DIR/run" XDG_STATE_HOME= \
        HYPRLAND_INSTANCE_SIGNATURE=sig sh "$HOME_DIR/.config/quickshell/start.sh" 2>&1)" || true
}

# shell_dies: a scratch HOME whose shell, the first time it runs, exits 139 with the session locked, and
# then exits cleanly. Records each program in $CALLS.
shell_dies() {
    changer_home
    cp "$QS_DIR/start.sh" "$HOME_DIR/.dotfiles/common/.config/quickshell/"
    cat >"$HOME_DIR/bin/quickshell" <<'SHIM'
#!/bin/sh
echo quickshell >>"$HOME/program-order"
[ -e "$HOME/died" ] && exit 0
touch "$HOME/died"
echo locked >"$XDG_RUNTIME_DIR/quickshell-locked"
exit 139
SHIM
    cat >"$HOME_DIR/bin/hyprlock" <<'SHIM'
#!/bin/sh
echo hyprlock >>"$HOME/program-order"
SHIM
    chmod +x "$HOME_DIR/bin/quickshell" "$HOME_DIR/bin/hyprlock"
    mkdir -p "$HOME_DIR/run/hypr/sig" "$HOME_DIR/run/quickshell/by-id/abc"
    echo compositor >"$HOME_DIR/run/hypr/sig/hyprland.log"
    echo shell >"$HOME_DIR/run/quickshell/by-id/abc/log.log"
    run_start_sh
}

failures() { echo "$HOME_DIR/.local/state/quickshell/lock-failures"; }

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

test_a_shell_that_exits_unlocked_is_left_alone() {
    shell_dies
    rm -rf "$HOME_DIR/program-order" "$HOME_DIR/run/quickshell-locked" "$(failures)"
    touch "$HOME_DIR/died" "$HOME_DIR/run/quickshell-locked"
    run_start_sh
    [[ "$(tr '\n' ' ' <"$HOME_DIR/program-order")" == "quickshell " ]] \
        || fail "ran: $(cat "$HOME_DIR/program-order")"
    [[ ! -e "$(failures)" ]] || fail "saved a failure that didn't happen"
}

test_a_shell_that_dies_locked_gets_hyprlock_then_starts_again() {
    shell_dies
    [[ "$(tr '\n' ' ' <"$HOME_DIR/program-order")" == "quickshell hyprlock quickshell " ]] \
        || fail "ran: $(cat "$HOME_DIR/program-order")"
}

test_the_shell_started_again_doesnt_count_as_locked() {
    shell_dies
    [[ ! -s "$HOME_DIR/run/quickshell-locked" ]] || fail "still marked locked"
}

test_a_shell_that_dies_locked_leaves_its_exit_status_and_logs() {
    shell_dies
    local saved
    saved="$(ls -d "$(failures)"/* | head -1)"
    grep -qx 139 "$saved/exit-status" || fail "no exit status in: $(ls -R "$(failures)")"
    grep -qx compositor "$saved/hyprland.log" || fail "no compositor log"
    grep -qx shell "$saved/log.log" || fail "no shell log"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
