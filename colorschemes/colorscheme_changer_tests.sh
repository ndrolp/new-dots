#!/usr/bin/env bash
# Tests for applying a colorscheme with colorscheme_changer.sh. The changer runs against a scratch HOME
# holding a copy of the colorschemes, and every program it drives is a PATH shim that logs its calls, so
# the live session is never touched. (This file sits beside the changer rather than in a tests/ folder
# because every folder in colorschemes/ is listed as a colorscheme.)
# Run: colorschemes/colorscheme_changer_tests.sh [name filter]
set -uo pipefail

COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    echo "  calls:"
    sed 's/^/    | /' "$CALLS" 2>/dev/null
    return 1
}

# change_colorscheme [--failing "<tool>..."] <args>...: runs the changer with <args>. Every program it
# drives is a shim that logs "<tool> <args>" to $CALLS; the --failing ones also exit 1. Sets OUT to the
# changer's output and NOTIFICATIONS to the notify-send calls, one per line.
change_colorscheme() {
    local failing="" home bin tool
    if [[ "$1" == --failing ]]; then
        failing="$2"
        shift 2
    fi
    home="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$home/bin"
    mkdir -p "$home/.dotfiles" "$bin" "$home/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$COLORSCHEMES" "$home/.dotfiles/colorschemes"
    for tool in hyprctl kitten ags quickshell gsettings rofi node setsid notify-send; do
        cat >"$bin/$tool" <<SHIM
#!/bin/sh
echo "$tool \$*" >>"\$HOME/calls"
case " $failing " in *" $tool "*) exit 1 ;; esac
exit 0
SHIM
    done
    chmod +x "$bin"/*
    CALLS="$home/calls"
    : >"$CALLS"
    OUT="$(HOME="$home" PATH="$bin:$PATH" bash "$home/.dotfiles/colorschemes/colorscheme_changer.sh" "$@" 2>&1)"
    NOTIFICATIONS="$(grep "^notify-send " "$CALLS" || true)"
}

calls_to() { grep -c "^$1 " "$CALLS" || true; }

test_a_failing_step_does_not_stop_the_later_steps() {
    change_colorscheme --failing "kitten" nord
    [[ "$(calls_to quickshell)" -gt 0 ]] || fail "quickshell was never restarted after kitty failed"
}

test_an_apply_with_failed_steps_sends_one_notification_naming_them() {
    change_colorscheme --failing "kitten gsettings" nord
    [[ "$(calls_to notify-send)" -eq 1 ]] || fail "expected exactly one notification"
    [[ "$NOTIFICATIONS" == *kitty* && "$NOTIFICATIONS" == *gtk* ]] || fail "notification does not name kitty and gtk"
    [[ "$NOTIFICATIONS" != *hyprland* ]] || fail "notification names a step that succeeded"
}

test_a_successful_apply_sends_no_notification() {
    change_colorscheme nord
    [[ -z "$NOTIFICATIONS" ]] || fail "a successful apply notified"
}

test_applying_does_not_ask_ags_for_the_theme() {
    change_colorscheme nord
    [[ "$(calls_to ags)" -eq 0 ]] || fail "ags was called"
}

test_previewing_only_reloads_hyprland() {
    change_colorscheme --preview nord
    [[ "$(cut -d' ' -f1 "$CALLS")" == hyprctl ]] || fail "preview drove more than hyprctl"
}

test_a_failing_preview_sends_no_notification() {
    change_colorscheme --failing hyprctl --preview nord
    [[ -z "$NOTIFICATIONS" ]] || fail "a preview notified"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
