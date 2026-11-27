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
        hl = setmetatable({ config = function(c) merge(config, c) end }, { __index = anything })
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

# borders_and_rounding_with <saved file contents | none>: like applied_with, but sets OUT to the border
# size and the corner radius Hyprland ends up with.
borders_and_rounding_with() {
    applied_with "$1" "
        print((config.general or {}).border_size, (config.decoration or {}).rounding)
        os.exit(0)
    "
}

test_without_a_saved_file_the_border_size_and_rounding_are_the_defaults() {
    borders_and_rounding_with none
    [[ "$OUT" == $'2\t5' ]] || fail "wrong border size and rounding"
}

test_the_saved_border_size_and_rounding_apply() {
    borders_and_rounding_with '{ "border_size": 0, "rounding": 24 }'
    [[ "$OUT" == $'0\t24' ]] || fail "wrong border size and rounding"
}

test_a_bad_border_size_or_rounding_falls_back_alone() {
    borders_and_rounding_with '{ "border_size": 7, "rounding": 12 }'
    [[ "$OUT" == $'2\t12' ]] || fail "wrong border size and rounding"
    borders_and_rounding_with '{ "border_size": 4, "rounding": 25 }'
    [[ "$OUT" == $'4\t5' ]] || fail "wrong border size and rounding"
    borders_and_rounding_with '{ "border_size": 1.5, "rounding": "round" }'
    [[ "$OUT" == $'2\t5' ]] || fail "wrong border size and rounding"
    borders_and_rounding_with '{ "border_size": -1, "rounding": 0 }'
    [[ "$OUT" == $'2\t0' ]] || fail "wrong border size and rounding"
}

# The whole config, as a colorscheme change reloads it: the border size and rounding come from the
# saved file, the border colours from the colorscheme, and neither resets the other.
test_the_full_config_gives_the_saved_border_size_with_the_colorschemes_colours() {
    local copy
    copy="$(mktemp -d "$SCRATCH/hypr.XXXX")"
    cp -r "$HYPR/." "$copy"
    rm -f "$copy/custom/colors.lua"
    printf 'return { accent = "#a7c080", border = "#4f5b58" }\n' >"$copy/custom/colors.lua"
    applied_with '{ "border_size": 5, "rounding": 9 }' "
        package.path = '$copy/?.lua'
        for name in pairs(package.loaded) do
            if name:match('^modules') or name:match('^custom') then package.loaded[name] = nil end
        end
        dofile('$copy/hyprland.lua')
        local general = config.general or {}
        print(general.border_size, general.col.active_border, general.col.inactive_border,
            (config.decoration or {}).rounding)
        os.exit(0)
    "
    [[ "$OUT" == $'5\trgb(a7c080)\trgb(4f5b58)\t9' ]] || fail "wrong borders"
}

# The colorscheme's borders module sets only the colours, so applying it never resets the saved size.
test_the_colorschemes_borders_leave_the_border_size_alone() {
    applied_with '{ "border_size": 5 }' "
        package.loaded['modules.appearence.borders'] = nil
        require('modules.appearence.borders')
        print(config.general.border_size)
        os.exit(0)
    "
    [[ "$OUT" == "5" ]] || fail "the colorscheme's borders reset the size"
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
