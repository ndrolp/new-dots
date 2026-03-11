#!/usr/bin/env bash

WAYBAR_COLORS="$HOME/.config/waybar/custom/colors.css"
HYPRLAND_COLORS="$HOME/.config/hypr/custom/colors.conf"
KITTY_COLORS="$HOME/.config/kitty/colors.conf"
NVIM_COLORS="$HOME/.config/nvim/lua/settings/core/theme.lua"
ROFI_COLORS="$HOME/.config/rofi/custom/colors.rasi"

TARGET_DIR="$HOME/.dotfiles/colorschemes"

# Theme state storage
THEME_STATE_DIR="$HOME/.dotfiles/colorschemes/"
THEME_FILE="$THEME_STATE_DIR/theme.txt"

capitalize() {
  local input="$1"
  local result=""
  for word in $input; do
    IFS='-' read -ra parts <<< "$word"
    for i in "${!parts[@]}"; do
      parts[$i]="${parts[$i]^}"
    done
    result+="${parts[*]-// /-} "
  done
  echo "${result::-1}"
}

SELECTED_FOLDER=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
  | sed '/^$/d' \
  | sort \
  | rofi -dmenu -l 5 -columns 1 -font "FiraCode Nerd Font 10" -no-show-icons -i)

[ -z "$SELECTED_FOLDER" ] && exit 0

# Store selected theme
mkdir -p "$THEME_STATE_DIR"
echo "$SELECTED_FOLDER" > "$THEME_FILE"

echo "$SELECTED_FOLDER"

CAPITALIZED_THEME=$(capitalize "$SELECTED_FOLDER")

THEME_FOLDER="$HOME/.dotfiles/colorschemes/$SELECTED_FOLDER"

echo "LINKING WAYBAR"
ln -sf "$THEME_FOLDER/waybar/colors.css" "$WAYBAR_COLORS"

echo "LINKING HYPR COLORS"
ln -sf "$THEME_FOLDER/hypr/colors.conf" "$HYPRLAND_COLORS"

cat "$THEME_FOLDER/hypr/colors.conf"

kitten themes --reload-in=all "$CAPITALIZED_THEME"

# APPLY NVIM THEME
echo "LINKING NVIM"
ln -sf "$THEME_FOLDER/nvim/theme.lua" "$NVIM_COLORS"

echo "LINKING ROFI"
ln -sf "$THEME_FOLDER/rofi/colors.rasi" "$ROFI_COLORS"

source "$THEME_FOLDER/gtk/colors.sh"

mkdir -p ~/.config/gtk-4.0
echo -e "[Settings]\ngtk-theme-name=THEME_NAME" > ~/.config/gtk-4.0/settings.ini

ags request theme "$SELECTED_FOLDER"

#===== MOVE WALLPAPERS =======

WALLPAPERS_FOLDER="$HOME/Pictures/[01] - Wallpapers/[02] - Current/"

ln -sf "$HOME/Pictures/[01] - Wallpapers/[01] - Default/$SELECTED_FOLDER/Horizontal" "$WALLPAPERS_FOLDER"
ln -sf "$HOME/Pictures/[01] - Wallpapers/[01] - Default/$SELECTED_FOLDER/Vertical" "$WALLPAPERS_FOLDER"

exec "$HOME/.dotfiles/scripts/hyprland/wallpaper.sh"

#=============================

sleep 0.3

# bash ~/.dotfiles/scripts/hyprland/reload.sh
