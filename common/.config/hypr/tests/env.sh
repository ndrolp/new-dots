#!/usr/bin/env bash
# Tests for the environment the Hyprland config sets. The config runs under plain luajit with `hl`
# stubbed to record hl.env calls, so no Hyprland is needed.
# Run: common/.config/hypr/tests/env.sh [name filter]
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# hypr_env: runs the whole Hyprland config with `hl` stubbed and sets OUT to the variables it sets,
# one NAME=value per line, in order.
hypr_env() {
    OUT="$(luajit -e "
        package.path = '$HYPR/?.lua'
        local anything = setmetatable({}, {})
        getmetatable(anything).__index = function() return anything end
        getmetatable(anything).__call = function() return anything end
        hl = setmetatable({ env = function(k, v) print(k .. '=' .. v) end }, { __index = anything })
        dofile('$HYPR/hyprland.lua')
    " 2>&1)"
}

# GTK apps export their menus over DBusMenu only when this module is loaded.
test_gtk_apps_load_the_appmenu_module() {
    hypr_env
    grep -qx "GTK_MODULES=appmenu-gtk-module" <<<"$OUT" || fail "GTK_MODULES is not appmenu-gtk-module"
}

# Forcing X11 or xcb would push every app onto XWayland just to get menus; the spec rules it out.
test_no_backend_is_forced() {
    hypr_env
    ! grep -qE "^(GDK_BACKEND|QT_QPA_PLATFORM)=" <<<"$OUT" || fail "a backend is forced"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
