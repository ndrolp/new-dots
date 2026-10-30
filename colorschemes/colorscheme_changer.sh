#!/usr/bin/env bash

WAYBAR_COLORS="$HOME/.config/waybar/custom/colors.css"
HYPRLAND_COLORS="$HOME/.config/hypr/custom/colors.conf"
HYPRLAND_LUA_COLORS="$HOME/.config/hypr/custom/colors.lua"
HYPRLOCK_COLORS="$HOME/.config/hypr/custom/hyprlock-colors.conf"
NVIM_COLORS="$HOME/.config/nvim/lua/settings/core/theme.lua"
ROFI_COLORS="$HOME/.config/rofi/custom/colors.rasi"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"

TARGET_DIR="$HOME/.dotfiles/colorschemes"

# Theme state storage
THEME_STATE_DIR="$HOME/.dotfiles/colorschemes/"
THEME_FILE="$THEME_STATE_DIR/theme.txt"

PREVIEW_MODE=false

if [ "${1:-}" = "--preview" ]; then
  PREVIEW_MODE=true
  shift
fi

SELECTED_FOLDER="${1:-}"

if [ -z "$SELECTED_FOLDER" ]; then
  SELECTED_FOLDER=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | sed '/^$/d' \
    | sort \
    | rofi -dmenu -l 5 -columns 1 -font "FiraCode Nerd Font 10" -no-show-icons -i)
fi

[ -z "$SELECTED_FOLDER" ] && exit 0
[ -d "$TARGET_DIR/$SELECTED_FOLDER" ] || exit 1

case "$SELECTED_FOLDER" in
  catppuccin)
    KITTY_THEME="Catppuccin"
    VSCODE_THEME="Catppuccin Mocha"
    ;;
  gruvboxdark) KITTY_THEME="Gruvbox Dark" ;;
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
  carbonfox) KITTY_THEME="Carbonfox" ;;
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
# (theme.txt) alone; the selector previews the active colorscheme again to leave the preview.
if [ "$PREVIEW_MODE" = true ]; then
  link_hypr_colors
  hyprctl reload
  recolour_quickshell
  exit 0
fi

# Only applying makes the colorscheme the active one.
mkdir -p "$THEME_STATE_DIR"
echo "$SELECTED_FOLDER" > "$THEME_FILE"

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

apply_waybar() {
  ln -sf "$THEME_FOLDER/waybar/colors.css" "$WAYBAR_COLORS"
}

apply_hyprland() {
  link_hypr_colors
  ln -sf "$THEME_FOLDER/hyprlock/colors.conf" "$HYPRLOCK_COLORS"
  hyprctl reload
}

apply_kitty() {
  kitten themes --reload-in=all "$KITTY_THEME"
}

# New nvims load the linked theme.lua at startup; running ones re-source it through their server
# socket. Every socket is tried, and any that can't be reached fails the step afterwards.
apply_nvim() {
  ln -sf "$THEME_FOLDER/nvim/theme.lua" "$NVIM_COLORS"
  [ -n "${XDG_RUNTIME_DIR:-}" ] || return 0

  local socket unreachable=0
  for socket in "$XDG_RUNTIME_DIR"/nvim.*.0; do
    [ -e "$socket" ] || continue
    timeout 5 nvim --server "$socket" --remote-expr "execute('source $NVIM_COLORS')" >/dev/null \
      || unreachable=1
  done
  return "$unreachable"
}

apply_rofi() {
  ln -sf "$THEME_FOLDER/rofi/colors.rasi" "$ROFI_COLORS"
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

step waybar apply_waybar
step hyprland apply_hyprland
step kitty apply_kitty
step nvim apply_nvim
step rofi apply_rofi
step vscode apply_vscode
step gtk apply_gtk
step quickshell apply_quickshell

report_failed_steps
