#!/usr/bin/env bash
# Tests for the shell's layer rules: what Hyprland ends up applying to a layer namespace. The whole
# Hyprland config runs under plain luajit with `hl` stubbed to record its layer rules, so no Hyprland
# is needed. Rules matching a namespace apply in order, a later one overriding an earlier one.
# Run: common/.config/hypr/tests/layer-rules.sh [name filter]
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# layer_effects <namespace>: runs the full config and sets OUT to the blur, ignore_alpha and dim_around
# that the layer rules matching <namespace> leave it with ("nil" when no rule sets one).
layer_effects() {
    OUT="$(luajit -e "
        package.path = '$HYPR/?.lua'
        local rules = {}
        local anything = setmetatable({}, {})
        getmetatable(anything).__index = function() return anything end
        getmetatable(anything).__call = function() return anything end
        hl = setmetatable({ layer_rule = function(r) rules[#rules + 1] = r end }, { __index = anything })
        dofile('$HYPR/hyprland.lua')
        local effects = {}
        for _, rule in ipairs(rules) do
            local pattern = rule.match and rule.match.namespace or ''
            for alternative in pattern:gmatch('[^|]+') do
                if alternative == '$1' then
                    for k, v in pairs(rule) do effects[k] = v end
                    break
                end
            end
        end
        print(tostring(effects.blur), tostring(effects.ignore_alpha), tostring(effects.dim_around))
    " 2>&1)"
}

# The centered settings panel is translucent: Hyprland blurs behind it, only behind its drawn area
# (the rest of its full-screen layer is fully transparent), and still dims the desktop around it.
test_the_settings_layer_is_blurred_behind_its_drawn_area_only() {
    layer_effects ndro-shell-settings
    [[ "$OUT" == $'true\t0\ttrue' ]] || fail "expected blur, ignore_alpha 0 and dim_around"
}

test_notifications_stay_unblurred() {
    layer_effects ndro-shell-notifications
    [[ "$OUT" == $'false\t0\tfalse' ]] || fail "expected no blur"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
