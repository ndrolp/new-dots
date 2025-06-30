#!/bin/bash

HYPRLAND_PATH="$HOME/.config/hypr"
WAYBAR_PATH="$HOME/.config/waybar"

if [ -z "$1" ]; then
  echo "Usage: switch-theme.sh <theme>"
  exit 1
fi

THEME=$1

if [ ! -d "$HYPRLAND_PATH/themes/$THEME" ]; then
  echo "Theme $THEME not found in Hyprland themes."
  exit 1
fi

if [ ! -f "$WAYBAR_PATH/themes/$THEME.css" ]; then
  echo "Theme $THEME not found in Waybar themes."
  exit 1
fi

# Update Hyprland
ln -sf "$HYPRLAND_PATH/themes/$THEME" "$HYPRLAND_PATH/current"
hyprctl reload

# Update Waybar
ln -sf "$WAYBAR_PATH/themes/$THEME.css" "$WAYBAR_PATH/current.css"
pkill -USR2 waybar

echo "Switched to theme $THEME."
