#!/usr/bin/env bash
# The WindowAppearance service, for real: a headless `qs` on a scratch config with a scratch
# XDG_CONFIG_HOME and a `hyprctl` shim on PATH, so no live session is touched. A change writes
# ~/.config/hypr/window-appearance.json and asks Hyprland to re-run only the window-appearance module.
# Run: common/.config/quickshell/tests/window-appearance.sh
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "${OUT:-}" | sed 's/^/    | /'
    return 1
}

# run_service <saved file contents | none> <qml run once the service is up>: starts the service
# headless with `service` in scope, waits a moment, then quits. Sets OUT to what qs printed, and leaves
# the saved file in $CONFIG/hypr and each hyprctl call, one per line, in $SCRATCH/hyprctl.
run_service() {
    local cfg
    cfg="$(mktemp -d "$SCRATCH/cfg.XXXX")"
    CONFIG="$(mktemp -d "$SCRATCH/config.XXXX")"
    mkdir -p "$cfg/services" "$CONFIG/hypr" "$SCRATCH/run" "$SCRATCH/bin"
    chmod 700 "$SCRATCH/run"
    rm -f "$SCRATCH/hyprctl"
    [[ "$1" == none ]] || printf '%s\n' "$1" >"$CONFIG/hypr/window-appearance.json"
    printf '#!/bin/sh\necho "$*" >>"%s/hyprctl"\n' "$SCRATCH" >"$SCRATCH/bin/hyprctl"
    chmod +x "$SCRATCH/bin/hyprctl"
    cp "$QS_DIR/services/WindowAppearance.qml" "$QS_DIR/services/WindowAppearance.js" "$cfg/services/"
    cat >"$cfg/shell.qml" <<QML
import Quickshell
import QtQuick
import "services" as Services

ShellRoot {
    Services.WindowAppearance { id: service }
    Timer { interval: 300; running: true; onTriggered: { $2 } }
    Timer { interval: 1500; running: true; onTriggered: Qt.quit() }
}
QML
    OUT="$(cd "$SCRATCH" && env -u HYPRLAND_INSTANCE_SIGNATURE -u WAYLAND_DISPLAY -u DISPLAY \
        PATH="$SCRATCH/bin:$PATH" XDG_CONFIG_HOME="$CONFIG" QT_QPA_PLATFORM=offscreen \
        XDG_RUNTIME_DIR="$SCRATCH/run" timeout 20 qs -p "$cfg/shell.qml" 2>&1)"
}

test_a_change_writes_the_file_and_applies_only_the_window_appearance_module() {
    command -v qs >/dev/null || { echo "  SKIP: qs not installed"; return 0; }
    run_service none 'service.set("gaps_in", 12)'
    jq -e '. == { "gaps_in": 12, "gaps_out": 10 }' "$CONFIG/hypr/window-appearance.json" >/dev/null \
        || fail "wrong file: $(cat "$CONFIG/hypr/window-appearance.json" 2>&1)"
    [[ "$(cat "$SCRATCH/hyprctl" 2>&1)" == 'eval require("modules.appearence.windows").apply()' ]] \
        || fail "wrong hyprctl calls: $(cat "$SCRATCH/hyprctl" 2>&1)"
}

test_a_change_keeps_the_other_saved_values() {
    command -v qs >/dev/null || { echo "  SKIP: qs not installed"; return 0; }
    run_service '{ "gaps_in": 3, "gaps_out": 40 }' 'console.log("shown", service.values.gaps_in); service.set("gaps_in", 8)'
    [[ "$OUT" == *"shown 3"* ]] || fail "didn't show the saved value"
    jq -e '. == { "gaps_in": 8, "gaps_out": 40 }' "$CONFIG/hypr/window-appearance.json" >/dev/null \
        || fail "wrong file: $(cat "$CONFIG/hypr/window-appearance.json" 2>&1)"
}

# A slider being dragged: many changes at once are one write and one apply, of the last value.
test_a_drag_is_written_and_applied_once_with_its_last_value() {
    command -v qs >/dev/null || { echo "  SKIP: qs not installed"; return 0; }
    run_service none 'for (let gap = 1; gap <= 20; gap++) service.set("gaps_out", gap)'
    jq -e '.gaps_out == 20' "$CONFIG/hypr/window-appearance.json" >/dev/null \
        || fail "wrong file: $(cat "$CONFIG/hypr/window-appearance.json" 2>&1)"
    [[ "$(wc -l <"$SCRATCH/hyprctl")" -eq 1 ]] || fail "hyprctl calls: $(cat "$SCRATCH/hyprctl")"
}

for test in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$test"
    if ( set -e; "$test" ); then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

echo
echo "$PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
