#!/usr/bin/env bash
# Tests for the window borders following the colorscheme. The Hyprland config runs under plain luajit
# with `hl` stubbed to record what it is given, so no Hyprland is needed.
# Run: common/.config/hypr/tests/borders.sh
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

# borders_with <colors.lua contents | none>: loads the borders module from a config dir whose
# custom/colors.lua holds the given Lua (or does not exist) and sets OUT to the border settings it applied.
borders_with() {
    local config
    config="$(mktemp -d "$SCRATCH/config.XXXX")"
    mkdir -p "$config/modules/appearence" "$config/custom"
    cp "$HYPR/modules/appearence/borders.lua" "$config/modules/appearence/"
    [[ "$1" != none ]] && printf '%s\n' "$1" >"$config/custom/colors.lua"
    OUT="$(luajit -e "
        package.path = '$config/?.lua'
        local general = {}
        hl = { config = function(c) for k, v in pairs(c.general or {}) do general[k] = v end end }
        require('modules.appearence.borders')
        print(general.border_size, general.col.active_border, general.col.inactive_border)
    " 2>&1)"
}

expect_out() {
    if [[ "$OUT" == "$1" ]]; then
        PASSED=$((PASSED + 1))
    else
        echo "  FAIL: $2"
        echo "    expected: $1"
        echo "    actual:   $OUT"
        FAILED=$((FAILED + 1))
    fi
}

borders_with 'return { accent = "#a7c080", border = "#4f5b58" }'
expect_out $'2\trgb(a7c080)\trgb(4f5b58)' "the focused border takes the accent and unfocused ones the border colour"

borders_with none
expect_out $'2\trgba(535353ee)\trgba(2b2b2baa)' "without colours the borders fall back to the greys"

borders_with 'error("broken")'
expect_out $'2\trgba(535353ee)\trgba(2b2b2baa)' "a colours file that fails to load falls back to the greys"

# Hyprland's require hands back an empty table when a module errors while loading.
borders_with 'return {}'
expect_out $'2\trgba(535353ee)\trgba(2b2b2baa)' "colours missing a value fall back to the greys"

# Each colorscheme's Hyprland colours are copied by hand from its Quickshell theme; they must agree.
COLORSCHEMES="$HYPR/../../../colorschemes"
for theme in "$COLORSCHEMES"/*/quickshell/Theme.qml; do
    name="$(basename "$(dirname "$(dirname "$theme")")")"
    qml() { sed -n "s/.*property color $1: \"\(#[0-9a-fA-F]*\)\".*/\1/p" "$theme"; }
    borders_with "$(cat "$COLORSCHEMES/$name/hypr/colors.lua" 2>/dev/null || echo 'return {}')"
    expect_out $'2\trgb('"$(qml accent | tr -d '#')"$')\trgb('"$(qml border | tr -d '#')"')' \
        "$name's Hyprland colours match its Quickshell accent and border"
done

# The whole Hyprland config, with the colours link as tracked in the repo (everforestdark), ends up with
# everforestdark's borders: no later setting overrides them.
config="$(mktemp -d "$SCRATCH/full.XXXX")"
cp -r "$HYPR/." "$config"
tracked="$(readlink "$HYPR/custom/colors.lua")"
ln -sf "$COLORSCHEMES/${tracked#*/colorschemes/}" "$config/custom/colors.lua"
OUT="$(luajit -e "
    package.path = '$config/?.lua'
    local general = {}
    local anything = setmetatable({}, {})
    getmetatable(anything).__index = function() return anything end
    getmetatable(anything).__call = function() return anything end
    hl = setmetatable({ config = function(c) for k, v in pairs(c.general or {}) do general[k] = v end end },
        { __index = anything })
    dofile('$config/hyprland.lua')
    print(general.border_size, general.col.active_border, general.col.inactive_border)
" 2>&1)"
expect_out $'2\trgb(a7c080)\trgb(4f5b58)' "the full config with the tracked colours link gives everforestdark's borders"

# change_colorscheme <args>...: runs the colorscheme changer against a scratch HOME holding a copy of the
# colorschemes. Every program it drives is a PATH shim; hyprctl records which colours file the Hyprland
# colours link points at when it is asked to reload. Sets OUT to that record.
change_colorscheme() {
    local home bin tool
    home="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$home/bin"
    mkdir -p "$home/.dotfiles" "$bin" "$home/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$COLORSCHEMES" "$home/.dotfiles/colorschemes"
    for tool in kitten ags quickshell gsettings rofi node setsid; do
        printf '#!/bin/sh\n' >"$bin/$tool"
    done
    printf '#!/bin/sh\nreadlink "$HOME/.config/hypr/custom/colors.lua" >>"$HOME/reloads"\n' >"$bin/hyprctl"
    chmod +x "$bin"/*
    HOME="$home" PATH="$bin:$PATH" bash "$COLORSCHEMES/colorscheme_changer.sh" "$@" >/dev/null 2>&1
    OUT="$(sed "s|^$home|~|" "$home/reloads" 2>/dev/null)"
}

change_colorscheme nord
expect_out "~/.dotfiles/colorschemes/nord/hypr/colors.lua" \
    "changing colorscheme links its Hyprland colours before reloading Hyprland"

change_colorscheme --preview tokyonight
expect_out "~/.dotfiles/colorschemes/tokyonight/hypr/colors.lua" \
    "previewing a colorscheme links its Hyprland colours before reloading Hyprland"

echo "borders: $PASSED passed, $FAILED failed"
((FAILED == 0))
