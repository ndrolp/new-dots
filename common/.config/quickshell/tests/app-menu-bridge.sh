#!/usr/bin/env bash
# The app menu bridge finds a native Wayland window's menus. Runs the real
# app-menu-bridge.py against a fake app (fixtures/fake-menu-app.py) on a private
# session bus: it needs no display and touches no live session.
# Usage: common/.config/quickshell/tests/app-menu-bridge.sh [name filter]
set -uo pipefail

if [[ -z "${APP_MENU_BRIDGE_TEST_BUS:-}" ]]; then
    APP_MENU_BRIDGE_TEST_BUS=1 exec dbus-run-session -- bash "${BASH_SOURCE[0]}" "$@"
fi

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE="$QS_DIR/services/app-menu-bridge.py"
FAKE_APP="$QS_DIR/tests/fixtures/fake-menu-app.py"
SCRATCH="$(mktemp -d)"
FAKE_PID=""
BRIDGE_PID=""
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | cut -c1-400 | sed 's/^/    | /'
    return 1
}

stop() {
    [[ -n "$BRIDGE_PID" ]] && kill "$BRIDGE_PID" 2>/dev/null
    [[ -n "$FAKE_PID" ]] && kill "$FAKE_PID" 2>/dev/null
    FAKE_PID=""
    BRIDGE_PID=""
}

# focus_on <scenario>: starts the fake app and the bridge, focuses the app's
# window as a native Wayland one and sets OUT to the bridge's first answer.
focus_on() {
    SIGNAL="$SCRATCH/$1"
    rm -f "$SIGNAL"
    python3 "$FAKE_APP" "$1" "$SIGNAL" &
    FAKE_PID=$!
    for _ in {1..100}; do
        [[ -e "$SIGNAL" ]] && break
        sleep 0.02
    done
    [[ -e "$SIGNAL" ]] || { OUT="the fake app never started"; return 1; }
    coproc BRIDGE_PROC { python3 "$BRIDGE"; }
    BRIDGE_PID=$BRIDGE_PROC_PID
    exec 3>&"${BRIDGE_PROC[1]}" 4<&"${BRIDGE_PROC[0]}"
    echo "{\"focus\": {\"pid\": $FAKE_PID, \"title\": \"Fake\", \"xwayland\": false}}" >&3
    OUT=""
    while read -r -t 5 line <&4; do
        [[ "$line" == *'"pid"'* ]] && { OUT="$line"; break; }
    done
    [[ -n "$OUT" ]]
}

service() {
    sed -E 's/.*"service": "([^"]+)".*/\1/' <<<"$OUT"
}

test_a_windows_menubar_is_found() {
    focus_on menubar || fail "no answer"
    grep -q '"label": "File"' <<<"$OUT" || fail "File is missing"
    grep -q '"label": "Open"' <<<"$OUT" || fail "Open is missing"
    grep -q '"menuPath": "/org/appmenu/gtk/window/menus/menubar/0"' <<<"$OUT" || fail "wrong menu path"
}

test_a_gtk_applications_menubar_is_found_with_its_actions() {
    focus_on application || fail "no answer"
    grep -q '"label": "About"' <<<"$OUT" || fail "About is missing"
    grep -q '"app": "/org/example/Fake"' <<<"$OUT" || fail "no app actions"
    grep -q '"win": "/org/example/Fake/window/1"' <<<"$OUT" || fail "no window actions"
    grep -q '"win.close"' <<<"$OUT" || fail "win.close is missing"
}

test_choosing_an_item_runs_it_in_the_app() {
    focus_on application || fail "no answer"
    echo "{\"activate\": {\"kind\": \"gtkAction\", \"service\": \"$(service)\", \"path\": \"/org/example/Fake/window/1\", \"name\": \"close\"}}" >&3
    for _ in {1..100}; do
        grep -qx close "$SIGNAL" && return 0
        sleep 0.02
    done
    fail "win.close never ran"
}

# Nemo's case: the paths exist but hold nothing, so showing them would be an
# app menu with no titles.
test_a_hidden_menubar_exports_nothing() {
    focus_on hidden-menubar || fail "no answer"
    grep -q '"exported": null' <<<"$OUT" || fail "an empty menubar was handed over"
}

test_an_app_with_no_menus_exports_nothing() {
    focus_on no-menus || fail "no answer"
    grep -q '"exported": null' <<<"$OUT" || fail "menus came from nowhere"
}

# Wayland doesn't tell which window of a process is focused, so a menu could
# act on the wrong one; no menu is better.
test_several_windows_with_menubars_export_nothing() {
    focus_on two-windows || fail "no answer"
    grep -q '"exported": null' <<<"$OUT" || fail "a menu was picked at random"
}

test_several_gtk_application_windows_export_nothing() {
    focus_on two-application-windows || fail "no answer"
    grep -q '"exported": null' <<<"$OUT" || fail "win actions were picked at random"
}

# GTK apps keep a connection that never answers (Nemo and kitty both do).
test_a_silent_connection_does_not_hide_the_menus() {
    focus_on silent-connection || fail "no answer"
    grep -q '"label": "Open"' <<<"$OUT" || fail "Open is missing"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    (
        set -e
        trap stop EXIT
        "$t"
    )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
