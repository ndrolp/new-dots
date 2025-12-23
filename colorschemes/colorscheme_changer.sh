#!/bin/bash

WAYBAR_COLORS="$HOME/.config/hypr/waybar/style/colors/colors.css"
HYPRLAND_COLORS="$HOME/.config/hypr/colors/colors.conf"
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

SELECTED_FOLDER=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | rofi -dmenu)

[ -z "$SELECTED_FOLDER" ] && exit 0

echo "$SELECTED_FOLDER"

CAPITALIZED_THEME=$(capitalize "$SELECTED_FOLDER")

THEME_FOLDER="$HOME/.dotfiles/colorschemes/$SELECTED_FOLDER"

echo "LINKING WAYBAR"
ln -sf "$THEME_FOLDER/waybar.css" "$WAYBAR_COLORS"
echo "LINKING HYPR COLORS"
ln -sf "$THEME_FOLDER/hyprland.conf" "$HYPRLAND_COLORS"

kitten themes --reload-in=all "$CAPITALIZED_THEME"


bash ~/.config/hypr/waybar/waybar.sh
