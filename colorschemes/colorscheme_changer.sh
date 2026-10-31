#!/usr/bin/env bash

HYPRLAND_COLORS="$HOME/.config/hypr/custom/colors.conf"
HYPRLAND_LUA_COLORS="$HOME/.config/hypr/custom/colors.lua"
NVIM_COLORS="$HOME/.config/nvim/lua/settings/core/theme.lua"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"

TARGET_DIR="$HOME/.dotfiles/colorschemes"

# The active colorscheme is machine-local (docs/adr/0001-active-colorscheme-is-machine-local.md): the
# gitignored link `active` names it, and the tracked colour links (waybar, hyprlock, nvim, rofi) point
# through it, so applying moves only this link. default.txt, tracked, names the default colorscheme,
# which `active` starts from whenever it is missing; an apply never writes it.
ACTIVE_LINK="$TARGET_DIR/active"
DEFAULT_FILE="$TARGET_DIR/default.txt"

# ensure_active: creates the active link from the default colorscheme when it is missing.
ensure_active() {
  [ -L "$ACTIVE_LINK" ] && [ -d "$ACTIVE_LINK" ] && return 0
  ln -sfn "$(cat "$DEFAULT_FILE")" "$ACTIVE_LINK"
}

ensure_active

# list_colorschemes: every colorscheme, one per line, sorted; the active link is not a folder, so it is
# not listed.
list_colorschemes() {
  find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# --list prints the colorschemes (the theme selector lists them this way).
if [ "${1:-}" = "--list" ]; then
  list_colorschemes
  exit 0
fi

# --active prints the active colorscheme (the theme selector reads it this way) and changes nothing else.
if [ "${1:-}" = "--active" ]; then
  basename "$(readlink "$ACTIVE_LINK")"
  exit 0
fi

PREVIEW_MODE=false

if [ "${1:-}" = "--preview" ]; then
  PREVIEW_MODE=true
  shift
fi

SELECTED_FOLDER="${1:-}"

if [ -z "$SELECTED_FOLDER" ]; then
  SELECTED_FOLDER=$(list_colorschemes \
    | rofi -dmenu -l 5 -columns 1 -font "FiraCode Nerd Font 10" -no-show-icons -i)
fi

[ -z "$SELECTED_FOLDER" ] && exit 0
list_colorschemes | grep -qxF -- "$SELECTED_FOLDER" || exit 1

case "$SELECTED_FOLDER" in
  catppuccin)
    KITTY_THEME="Catppuccin"
    VSCODE_THEME="Catppuccin Mocha"
    ;;
  gruvboxdark)
    KITTY_THEME="Gruvbox Dark"
    VSCODE_THEME="Gruvbox Dark Medium"
    ;;
  tokyonight)
    KITTY_THEME="Tokyo Night"
    VSCODE_THEME="Tokyo Night"
    ;;
  everforest|everforestdark)
    KITTY_THEME="Everforestdark"
    VSCODE_THEME="Everforest Pro Dark"
    ;;
  kanagawa)
    KITTY_THEME="Kanagawa"
    VSCODE_THEME="Kanagawa"
    ;;
  rosepine)
    KITTY_THEME="Rosé Pine"
    VSCODE_THEME="Rosé Pine"
    ;;
  dracula)
    KITTY_THEME="Dracula"
    VSCODE_THEME="Dracula Theme"
    ;;
  carbonfox)
    KITTY_THEME="Carbonfox"
    VSCODE_THEME="Carbonfox"
    ;;
  nord)
    KITTY_THEME="nord"
    VSCODE_THEME="Nord"
    ;;
  bloodmoon)
    KITTY_THEME="Bloodmoon"
    VSCODE_THEME="Midnight Crimson"
    ;;
  coralnord)
    KITTY_THEME="Coralnord"
    VSCODE_THEME="Nord Wave"
    ;;
  *) KITTY_THEME="$SELECTED_FOLDER" ;;
esac

echo "$SELECTED_FOLDER"

THEME_FOLDER="$HOME/.dotfiles/colorschemes/$SELECTED_FOLDER"

link_hypr_colors() {
  ln -sf "$THEME_FOLDER/hypr/colors.conf" "$HYPRLAND_COLORS"
  ln -sf "$THEME_FOLDER/hypr/colors.lua" "$HYPRLAND_LUA_COLORS"
}

# The shell can't see the link change by itself, so it is asked to read its colours again: it
# recolours in place, without restarting.
recolour_quickshell() {
  ln -sf "$THEME_FOLDER/quickshell/colors.json" "$HOME/.config/quickshell/config/colors.json"
  quickshell ipc --path "$HOME/.config/quickshell" call colorscheme reload
}

# A colorscheme preview recolours Hyprland and Quickshell only and leaves the active colorscheme
# alone; the selector previews the active colorscheme again to leave the preview.
if [ "$PREVIEW_MODE" = true ]; then
  link_hypr_colors
  hyprctl reload
  recolour_quickshell
  exit 0
fi

# Only applying makes the colorscheme the active one.
ln -sfn "$SELECTED_FOLDER" "$ACTIVE_LINK"

# Steps: each one updates one part of the desktop. `step <name> <function> [args...]` runs the function
# in a subshell with errexit and pipefail, so its first failing command fails the step, and a failed step
# never stops the ones after it. Once every step has run, one notification names the failed steps; a
# fully successful apply is silent. A new step is an apply_<name> function plus one `step` line below.
FAILED_STEPS=()

step() {
  local name="$1"
  shift
  echo "==> $name"
  (
    set -eo pipefail
    "$@"
  )
  [ $? -eq 0 ] || FAILED_STEPS+=("$name")
}

report_failed_steps() {
  [ ${#FAILED_STEPS[@]} -eq 0 ] && return 0
  local names
  names="$(printf '%s, ' "${FAILED_STEPS[@]}")"
  notify-send -u critical "Colorscheme $SELECTED_FOLDER applied with errors" \
    "Failed steps: ${names%, }"
}

apply_hyprland() {
  link_hypr_colors
  hyprctl reload
}

apply_kitty() {
  kitten themes --reload-in=all "$KITTY_THEME"
}

# New nvims load theme.lua, linked through the active colorscheme, at startup; running ones re-source it through their server
# socket. Every socket is tried, and any that can't be reached fails the step afterwards.
apply_nvim() {
  [ -n "${XDG_RUNTIME_DIR:-}" ] || return 0

  local socket unreachable=0
  for socket in "$XDG_RUNTIME_DIR"/nvim.*.0; do
    [ -e "$socket" ] || continue
    timeout 5 nvim --server "$socket" --remote-expr "execute('source $NVIM_COLORS')" >/dev/null \
      || unreachable=1
  done
  return "$unreachable"
}

apply_vscode() {
  [ -n "${VSCODE_THEME:-}" ] && [ -f "$VSCODE_SETTINGS" ] || return 0
  node - "$VSCODE_SETTINGS" "$VSCODE_THEME" <<'NODE'
const fs = require("fs");
const [settingsPath, theme] = process.argv.slice(2);
const settings = fs.readFileSync(settingsPath, "utf8");
const themeSetting = /("workbench\.colorTheme"\s*:\s*)"[^"]*"/;

if (!themeSetting.test(settings))
  throw new Error("VS Code's workbench.colorTheme setting was not found.");

const updated = settings.replace(themeSetting, (_, prefix) =>
  prefix + JSON.stringify(theme));
const temporaryPath = settingsPath + ".theme-update";
fs.writeFileSync(temporaryPath, updated);
fs.renameSync(temporaryPath, settingsPath);
NODE
}

# GTK3 apps restyle live through gsettings, and settings.ini names the same theme so the two can't drift.
# A theme without GTK4 files still applies to GTK3; the GTK4 links are left alone and the step fails.
apply_gtk() {
  local theme link settings="$HOME/.config/gtk-3.0/settings.ini"
  theme="$(sed -n 's/.*gtk-theme "\(.*\)".*/\1/p' "$THEME_FOLDER/gtk/colors.sh")"
  [ -n "$theme" ]
  if [ ! -d "$HOME/.themes/$theme" ]; then
    echo "GTK theme $theme is not installed in ~/.themes" >&2
    return 1
  fi

  gsettings set org.gnome.desktop.interface gtk-theme "$theme"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark

  mkdir -p "$(dirname "$settings")"
  [ -f "$settings" ] || echo "[Settings]" >"$settings"
  if grep -q '^gtk-theme-name=' "$settings"; then
    sed -i --follow-symlinks "s|^gtk-theme-name=.*|gtk-theme-name=$theme|" "$settings"
  else
    sed -i --follow-symlinks "/^\[Settings\]/a gtk-theme-name=$theme" "$settings"
  fi

  if [ ! -d "$HOME/.themes/$theme/gtk-4.0" ]; then
    echo "GTK theme $theme has no GTK4 files; GTK4 apps keep their theme" >&2
    return 1
  fi
  mkdir -p "$HOME/.config/gtk-4.0"
  for link in gtk.css gtk-dark.css assets; do
    ln -sfn "$HOME/.themes/$theme/gtk-4.0/$link" "$HOME/.config/gtk-4.0/$link"
  done
}

apply_quickshell() {
  recolour_quickshell
}

step hyprland apply_hyprland
step kitty apply_kitty
step nvim apply_nvim
step vscode apply_vscode
step gtk apply_gtk
step quickshell apply_quickshell

report_failed_steps
