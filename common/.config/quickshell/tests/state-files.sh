#!/usr/bin/env bash
# Quickshell's runtime state (recent launcher apps, per-monitor wallpapers)
# belongs to one machine: it is untracked and gitignored, and Quickshell
# creates it when missing. Appearance settings stay tracked.
# Runs a real, headless `qs` on a scratch config: no live session is touched.
# Usage: common/.config/quickshell/tests/state-files.sh
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$QS_DIR/../../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

STATE_FILES=(
    common/.config/quickshell/services/launcher.json
    common/.config/quickshell/config/wallpapers.json
)

fail() {
    echo "  FAIL: $*"
    return 1
}

test_state_files_are_not_tracked() {
    for file in "${STATE_FILES[@]}"; do
        [[ -z "$(git -C "$REPO" ls-files -- "$file")" ]] || fail "$file is tracked"
    done
}

test_state_files_are_gitignored() {
    for file in "${STATE_FILES[@]}"; do
        git -C "$REPO" check-ignore -q --no-index -- "$file" || fail "$file is not gitignored"
    done
}

test_appearance_settings_are_still_tracked() {
    local file=common/.config/quickshell/config/appearance.json
    [[ -n "$(git -C "$REPO" ls-files -- "$file")" ]] || fail "$file is not tracked"
    ! git -C "$REPO" check-ignore -q --no-index -- "$file" || fail "$file is gitignored"
}

# Starts a headless qs on a scratch config holding the real LauncherHistory
# and Wallpapers services, without their state files, then quits.
test_quickshell_creates_missing_state_files() {
    command -v qs >/dev/null || { echo "  SKIP: qs not installed"; return 0; }
    local cfg="$SCRATCH/cfg" out
    mkdir -p "$cfg/services" "$cfg/config" "$SCRATCH/run"
    chmod 700 "$SCRATCH/run"
    cp "$QS_DIR/services/LauncherHistory.qml" "$cfg/services/"
    cp "$QS_DIR/config/Wallpapers.qml" "$QS_DIR/config/WallpaperModel.js" "$cfg/config/"
    cat >"$cfg/shell.qml" <<'QML'
import Quickshell
import QtQuick
import "services" as Services
import "config" as Config

ShellRoot {
    Services.LauncherHistory {}
    Config.Wallpapers {}
    Timer { interval: 1000; running: true; onTriggered: Qt.quit() }
}
QML
    out="$(cd "$SCRATCH" && env -u HYPRLAND_INSTANCE_SIGNATURE -u WAYLAND_DISPLAY -u DISPLAY \
        QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$SCRATCH/run" \
        timeout 20 qs -p "$cfg/shell.qml" 2>&1)"
    local file
    for file in services/launcher.json config/wallpapers.json; do
        [[ -s "$cfg/$file" ]] || { echo "$out" | sed 's/^/    | /'; fail "qs did not create $file"; return 1; }
    done
    jq -e '.recent == [] and .favorites == []' "$cfg/services/launcher.json" >/dev/null \
        || fail "launcher.json is not empty history: $(cat "$cfg/services/launcher.json")"
    jq -e '.assignments == {}' "$cfg/config/wallpapers.json" >/dev/null \
        || fail "wallpapers.json has assignments: $(cat "$cfg/config/wallpapers.json")"
}

for test in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$test"
    if "$test"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

echo
echo "$PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
