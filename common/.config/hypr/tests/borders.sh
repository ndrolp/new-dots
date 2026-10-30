#!/usr/bin/env bash
# Tests for the window borders following the colorscheme. The Hyprland config runs under plain luajit
# with `hl` stubbed to record what it is given, so no Hyprland is needed.
# Run: common/.config/hypr/tests/borders.sh [name filter]
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLORSCHEMES="$HYPR/../../../colorschemes"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

GREYS=$'2\trgba(535353ee)\trgba(2b2b2baa)'
EVERFOREST=$'2\trgb(a7c080)\trgb(4f5b58)'

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# run_hypr_config <config dir> <lua>: runs <lua> under luajit with the config dir on package.path and `hl`
# stubbed (hl.config records the general settings, anything else is accepted and ignored). Sets OUT to
# the border size and the active and inactive border colours it ends up with.
run_hypr_config() {
    OUT="$(luajit -e "
        package.path = '$1/?.lua'
        local general = {}
        local anything = setmetatable({}, {})
        getmetatable(anything).__index = function() return anything end
        getmetatable(anything).__call = function() return anything end
        hl = setmetatable({ config = function(c) for k, v in pairs(c.general or {}) do general[k] = v end end },
            { __index = anything })
        $2
        print(general.border_size, general.col.active_border, general.col.inactive_border)
    " 2>&1)"
}

# borders_with <colors.lua contents | none>: loads the borders module from a config dir whose
# custom/colors.lua holds the given Lua (or does not exist) and sets OUT to the border settings it applied.
borders_with() {
    local config
    config="$(mktemp -d "$SCRATCH/config.XXXX")"
    mkdir -p "$config/modules/appearence" "$config/custom"
    cp "$HYPR/modules/appearence/borders.lua" "$config/modules/appearence/"
    [[ "$1" != none ]] && printf '%s\n' "$1" >"$config/custom/colors.lua"
    run_hypr_config "$config" "require('modules.appearence.borders')"
}

# change_colorscheme <args>...: runs the colorscheme changer against a scratch HOME holding a copy of the
# colorschemes. Every program it drives is a PATH shim; hyprctl records which colours file the Hyprland
# colours link points at when it is asked to reload. XDG_RUNTIME_DIR holds no nvim sockets, so no running
# nvim is switched. Sets OUT to that record.
change_colorscheme() {
    local home bin tool
    home="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$home/bin"
    mkdir -p "$home/.dotfiles" "$bin" "$home/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$COLORSCHEMES" "$home/.dotfiles/colorschemes"
    for tool in kitten quickshell gsettings rofi node setsid notify-send; do
        printf '#!/bin/sh\n' >"$bin/$tool"
    done
    printf '#!/bin/sh\nreadlink "$HOME/.config/hypr/custom/colors.lua" >>"$HOME/reloads"\n' >"$bin/hyprctl"
    chmod +x "$bin"/*
    HOME="$home" XDG_RUNTIME_DIR="$home" PATH="$bin:$PATH" bash "$COLORSCHEMES/colorscheme_changer.sh" "$@" >/dev/null 2>&1
    OUT="$(sed "s|^$home|~|" "$home/reloads" 2>/dev/null)"
}

test_the_focused_border_takes_the_accent_and_unfocused_ones_the_border_colour() {
    borders_with 'return { accent = "#a7c080", border = "#4f5b58" }'
    [[ "$OUT" == "$EVERFOREST" ]] || fail "wrong borders"
}

test_without_colours_the_borders_fall_back_to_the_greys() {
    borders_with none
    [[ "$OUT" == "$GREYS" ]] || fail "did not fall back to the greys"
}

test_a_colours_file_that_fails_to_load_falls_back_to_the_greys() {
    borders_with 'error("broken")'
    [[ "$OUT" == "$GREYS" ]] || fail "did not fall back to the greys"
}

# Hyprland's require hands back an empty table when a module errors while loading.
test_colours_missing_a_value_fall_back_to_the_greys() {
    borders_with 'return {}'
    [[ "$OUT" == "$GREYS" ]] || fail "did not fall back to the greys"
}

# Each colorscheme's Hyprland colours are copied by hand from its Quickshell theme; they must agree.
test_each_colorschemes_hyprland_colours_match_its_quickshell_accent_and_border() {
    local theme name expected
    qml() { sed -n "s/.*property color $1: \"\(#[0-9a-fA-F]*\)\".*/\1/p" "$theme" | tr -d '#'; }
    for theme in "$COLORSCHEMES"/*/quickshell/Theme.qml; do
        name="$(basename "$(dirname "$(dirname "$theme")")")"
        borders_with "$(cat "$COLORSCHEMES/$name/hypr/colors.lua" 2>/dev/null || echo 'return {}')"
        expected=$'2\trgb('"$(qml accent)"$')\trgb('"$(qml border)"')'
        [[ "$OUT" == "$expected" ]] || fail "$name: expected $expected"
    done
}

# The whole Hyprland config, with the colours link as tracked in the repo (everforestdark), ends up with
# everforestdark's borders: no later setting overrides them.
test_the_full_config_with_the_tracked_colours_link_gives_everforestdarks_borders() {
    local config tracked
    config="$(mktemp -d "$SCRATCH/full.XXXX")"
    cp -r "$HYPR/." "$config"
    tracked="$(readlink "$HYPR/custom/colors.lua")"
    ln -sf "$COLORSCHEMES/${tracked#*/colorschemes/}" "$config/custom/colors.lua"
    run_hypr_config "$config" "dofile('$config/hyprland.lua')"
    [[ "$OUT" == "$EVERFOREST" ]] || fail "wrong borders"
}

test_changing_colorscheme_links_its_hyprland_colours_before_reloading_hyprland() {
    change_colorscheme nord
    [[ "$OUT" == "~/.dotfiles/colorschemes/nord/hypr/colors.lua" ]] || fail "wrong link at reload"
}

test_previewing_a_colorscheme_links_its_hyprland_colours_before_reloading_hyprland() {
    change_colorscheme --preview tokyonight
    [[ "$OUT" == "~/.dotfiles/colorschemes/tokyonight/hypr/colors.lua" ]] || fail "wrong link at reload"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
