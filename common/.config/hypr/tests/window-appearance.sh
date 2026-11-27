#!/usr/bin/env bash
# Tests for the window appearance the Windows section of the shell's settings saves
# (modules/appearence/windows.lua). The module runs under plain Lua with `hl` stubbed to record what it
# is given, so no Hyprland is needed. It needs Lua 5.3 or later for its JSON reader, not luajit.
# XDG_CONFIG_HOME is an empty folder, so the tests can't reach a real saved file.
# Run: common/.config/hypr/tests/window-appearance.sh [name filter]
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# applied_with <saved file contents | none | unreadable> [lua]: loads the window appearance module and
# applies it, with ~/.config/hypr/window-appearance.json holding the given text (or not there, or there
# but unreadable), then runs [lua], if given. Sets OUT to the gaps Hyprland ends up with, inner then outer.
applied_with() {
    local config
    config="$(mktemp -d "$SCRATCH/config.XXXX")"
    mkdir -p "$config/hypr"
    case "$1" in
        none) ;;
        unreadable) mkdir "$config/hypr/window-appearance.json" ;;
        *) printf '%s\n' "$1" >"$config/hypr/window-appearance.json" ;;
    esac
    OUT="$(XDG_CONFIG_HOME="$config" lua -e "
        package.path = '$HYPR/?.lua'
        local config = {}
        local function merge(into, from)
            for k, v in pairs(from) do
                if type(v) == 'table' then
                    into[k] = into[k] or {}
                    merge(into[k], v)
                else
                    into[k] = v
                end
            end
        end
        local anything = setmetatable({}, {})
        getmetatable(anything).__index = function() return anything end
        getmetatable(anything).__call = function() return anything end
        local window_rules = {}
        local function window_rule(spec)
            local rule = { spec = spec, enabled = spec.enabled ~= false }
            function rule:set_enabled(on) self.enabled = on end
            function rule:is_enabled() return self.enabled end
            window_rules[#window_rules + 1] = rule
            return rule
        end
        hl = setmetatable({ config = function(c) merge(config, c) end, window_rule = window_rule },
            { __index = anything })
        require('modules.appearence.windows').apply()
        ${2:-}
        local general = config.general or {}
        print(general.gaps_in, general.gaps_out)
    " 2>&1)"
}

DEFAULTS=$'5\t10'

test_without_a_saved_file_the_gaps_are_the_defaults() {
    applied_with none
    [[ "$OUT" == "$DEFAULTS" ]] || fail "wrong gaps"
}

test_the_saved_gaps_apply() {
    applied_with '{ "gaps_in": 8, "gaps_out": 0 }'
    [[ "$OUT" == $'8\t0' ]] || fail "wrong gaps"
}

test_a_gap_missing_from_the_file_is_its_default() {
    applied_with '{ "gaps_out": 30 }'
    [[ "$OUT" == $'5\t30' ]] || fail "wrong gaps"
}

test_a_gap_out_of_range_falls_back_alone() {
    applied_with '{ "gaps_in": 31, "gaps_out": 20 }'
    [[ "$OUT" == $'5\t20' ]] || fail "wrong gaps"
    applied_with '{ "gaps_in": 3, "gaps_out": 61 }'
    [[ "$OUT" == $'3\t10' ]] || fail "wrong gaps"
    applied_with '{ "gaps_in": -1, "gaps_out": 60 }'
    [[ "$OUT" == $'5\t60' ]] || fail "wrong gaps"
}

test_a_gap_that_isnt_a_whole_number_falls_back_alone() {
    applied_with '{ "gaps_in": "8", "gaps_out": 20 }'
    [[ "$OUT" == $'5\t20' ]] || fail "wrong gaps"
    applied_with '{ "gaps_in": 4, "gaps_out": 2.5 }'
    [[ "$OUT" == $'4\t10' ]] || fail "wrong gaps"
}

test_a_file_that_isnt_json_gives_the_defaults() {
    applied_with '{ "gaps_in": 8,'
    [[ "$OUT" == "$DEFAULTS" ]] || fail "wrong gaps"
    applied_with '[8, 20]'
    [[ "$OUT" == "$DEFAULTS" ]] || fail "wrong gaps"
}

test_an_unreadable_file_gives_the_defaults() {
    applied_with unreadable
    [[ "$OUT" == "$DEFAULTS" ]] || fail "wrong gaps"
}

# The shell runs apply again over `hyprctl eval` after writing the file: it reads the file anew.
test_applying_again_reads_the_file_again() {
    applied_with '{ "gaps_in": 8 }' "
        local file = io.open(os.getenv('XDG_CONFIG_HOME') .. '/hypr/window-appearance.json', 'w')
        file:write('{ \"gaps_in\": 12 }')
        file:close()
        require('modules.appearence.windows').apply()
    "
    [[ "$OUT" == $'12\t10' ]] || fail "wrong gaps"
}

# The whole Hyprland config applies the saved gaps, and no later setting overrides them.
test_the_full_config_applies_the_saved_gaps() {
    applied_with '{ "gaps_in": 7, "gaps_out": 9 }' "
        package.path = '$HYPR/?.lua'
        for name in pairs(package.loaded) do
            if name:match('^modules') then package.loaded[name] = nil end
        end
        dofile('$HYPR/hyprland.lua')
    "
    [[ "$OUT" == $'7\t9' ]] || fail "wrong gaps"
}

# blurred_with <saved file contents | none | unreadable> [lua]: like applied_with, but sets OUT to the
# blur size, whether blur is on at all (for the shell's layers too), then whether windows are blurred:
# they aren't when an enabled window rule matching every window turns blur off.
BLUR_PRINT="
    local blur = (config.decoration or {}).blur or {}
    local windows = true
    for _, rule in ipairs(window_rules) do
        if rule.enabled and rule.spec.no_blur and rule.spec.match and rule.spec.match.class == '.*' then
            windows = false
        end
    end
    print(blur.size, blur.enabled, windows)
    os.exit(0)
"
blurred_with() {
    applied_with "$1" "${2:-}
$BLUR_PRINT"
}

test_without_a_saved_file_windows_are_blurred_at_todays_strength() {
    blurred_with none "
        package.path = '$HYPR/?.lua'
        package.loaded['modules.appearence.windows'] = nil
        dofile('$HYPR/hyprland.lua')
    "
    [[ "$OUT" == $'7\ttrue\ttrue' ]] || fail "wrong blur"
}

test_the_saved_blur_strength_applies() {
    blurred_with '{ "blur_size": 12 }'
    [[ "$OUT" == $'12\tnil\ttrue' ]] || fail "wrong blur"
}

test_a_blur_strength_out_of_range_falls_back_to_todays() {
    blurred_with '{ "blur_size": 0 }'
    [[ "$OUT" == $'7\tnil\ttrue' ]] || fail "wrong blur"
    blurred_with '{ "blur_size": 16 }'
    [[ "$OUT" == $'7\tnil\ttrue' ]] || fail "wrong blur"
    blurred_with '{ "blur_size": 4.5 }'
    [[ "$OUT" == $'7\tnil\ttrue' ]] || fail "wrong blur"
}

# Window blur off is a window rule: blur itself stays on, so the bar, capsule and popups keep theirs.
test_window_blur_off_unblurs_only_windows() {
    blurred_with '{ "window_blur": false }' "
        package.path = '$HYPR/?.lua'
        for name in pairs(package.loaded) do
            if name:match('^modules') then package.loaded[name] = nil end
        end
        dofile('$HYPR/hyprland.lua')
    "
    [[ "$OUT" == $'7\ttrue\tfalse' ]] || fail "wrong blur"
}

test_window_blur_that_isnt_a_switch_falls_back_to_on() {
    blurred_with '{ "window_blur": "no" }'
    [[ "$OUT" == $'7\tnil\ttrue' ]] || fail "wrong blur"
}

# The shell applies again over hyprctl eval after each change: window blur goes off and back on.
test_applying_again_switches_window_blur_off_and_back_on() {
    blurred_with '{ "window_blur": true }' "
        local function save(text)
            local file = io.open(os.getenv('XDG_CONFIG_HOME') .. '/hypr/window-appearance.json', 'w')
            file:write(text)
            file:close()
            require('modules.appearence.windows').apply()
        end
        save('{ \"window_blur\": false }')
        save('{ \"window_blur\": true }')
    "
    [[ "$OUT" == $'7\tnil\ttrue' ]] || fail "window blur stayed off"
    blurred_with '{ "window_blur": true }' "
        local file = io.open(os.getenv('XDG_CONFIG_HOME') .. '/hypr/window-appearance.json', 'w')
        file:write('{ \"window_blur\": false }')
        file:close()
        require('modules.appearence.windows').apply()
    "
    [[ "$OUT" == $'7\tnil\tfalse' ]] || fail "window blur didn't go off"
}

test_the_saved_file_is_gitignored() {
    OUT=""
    git -C "$HYPR" check-ignore -q window-appearance.json || fail "window-appearance.json is not gitignored"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
