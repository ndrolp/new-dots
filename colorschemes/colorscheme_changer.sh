#!/bin/bash

WAYBAR_COLORS="$HOME/.config/waybar/custom/colors.css"
HYPRLAND_COLORS="$HOME/.config/hypr/custom/colors.conf"
KITTY_COLORS="$HOME/.config/kitty/colors.conf"

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
  echo "${result::-1}"  # remove trailing space
}

TARGET_DIR="$HOME/.dotfiles/colorschemes"

SELECTED_FOLDER=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
  | sort \
  | rofi -dmenu -l 5 -columns 1 -font "FiraCode Nerd Font 10")

[ -z "$SELECTED_FOLDER" ] && exit 0

echo "$SELECTED_FOLDER"

CAPITALIZED_THEME=$(capitalize "$SELECTED_FOLDER")

THEME_FOLDER="$HOME/.dotfiles/colorschemes/$SELECTED_FOLDER"

echo "LINKING WAYBAR"
ln -sf "$THEME_FOLDER/waybar/colors.css" "$WAYBAR_COLORS"
echo "LINKING HYPR COLORS"
ln -sf "$THEME_FOLDER/hypr/colors.conf" "$HYPRLAND_COLORS"

cat "$THEME_FOLDER/hypr/colors.conf"

kitten themes --reload-in=all "$CAPITALIZED_THEME"


bash ~/.dotfiles/scripts/hyprland/reload.sh
