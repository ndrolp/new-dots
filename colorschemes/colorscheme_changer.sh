#!/usr/bin/env bash

WAYBAR_COLORS="$HOME/.config/waybar/custom/colors.css"
HYPRLAND_COLORS="$HOME/.config/hypr/custom/colors.conf"
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
  *) KITTY_THEME="$SELECTED_FOLDER" ;;
esac

# Store selected theme
mkdir -p "$THEME_STATE_DIR"
echo "$SELECTED_FOLDER" > "$THEME_FILE"

echo "$SELECTED_FOLDER"

THEME_FOLDER="$HOME/.dotfiles/colorschemes/$SELECTED_FOLDER"

if [ "$PREVIEW_MODE" = true ]; then
  ln -sf "$THEME_FOLDER/hypr/colors.conf" "$HYPRLAND_COLORS"
  hyprctl reload
  exit 0
fi

echo "LINKING WAYBAR"
ln -sf "$THEME_FOLDER/waybar/colors.css" "$WAYBAR_COLORS"

echo "LINKING HYPR COLORS"
ln -sf "$THEME_FOLDER/hypr/colors.conf" "$HYPRLAND_COLORS"
ln -sf "$THEME_FOLDER/hyprlock/colors.conf" "$HYPRLOCK_COLORS"
hyprctl reload

echo "APPLYING KITTY THEME"
kitten themes --reload-in=all "$KITTY_THEME"

# APPLY NVIM THEME
echo "LINKING NVIM"
ln -sf "$THEME_FOLDER/nvim/theme.lua" "$NVIM_COLORS"

echo "LINKING ROFI"
ln -sf "$THEME_FOLDER/rofi/colors.rasi" "$ROFI_COLORS"

if [ -n "${VSCODE_THEME:-}" ] && [ -f "$VSCODE_SETTINGS" ]; then
  echo "APPLYING VS CODE THEME"
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
fi

source "$THEME_FOLDER/gtk/colors.sh"

mkdir -p ~/.config/gtk-4.0
echo -e "[Settings]\ngtk-theme-name=THEME_NAME" > ~/.config/gtk-4.0/settings.ini

ags request theme "$SELECTED_FOLDER"

echo "RESTARTING QUICKSHELL"
ln -sf "$THEME_FOLDER/quickshell/Theme.qml" "$HOME/.config/quickshell/config/Theme.qml"

# The apply process belongs to the running shell, so schedule its replacement
# independently before asking Quickshell to terminate the current instances.
setsid sh -c 'sleep 0.5; exec quickshell --path "$HOME/.config/quickshell" --daemonize' \
  </dev/null >/dev/null 2>&1 &

quickshell list --json \
  | sed -n 's/.*"pid":[[:space:]]*\([0-9][0-9]*\).*/\1/p' \
  | while read -r quickshell_pid; do
      quickshell kill --pid "$quickshell_pid"
    done
