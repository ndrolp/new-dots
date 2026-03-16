#!/usr/bin/env bash

# Directories
HORIZ="$HOME/Pictures/Wallpapers/Current/Horizontal"
VERT="$HOME/Pictures/Wallpapers/Current/Vertical"

# Get monitors JSON
MONITORS=$(hyprctl monitors -j)

# Let user pick monitor
MONITOR=$(echo "$MONITORS" | jq -r '.[].name' | rofi -dmenu -p "Monitor")
[ -z "$MONITOR" ] && exit

# Get width & height
WIDTH=$(echo "$MONITORS" | jq -r ".[] | select(.name==\"$MONITOR\") | .width")
HEIGHT=$(echo "$MONITORS" | jq -r ".[] | select(.name==\"$MONITOR\") | .height")

# Orientation
if (( WIDTH > HEIGHT )); then
    WALL_DIR="$HORIZ"
else
    WALL_DIR="$VERT"
fi

# Build Rofi menu with thumbnails
SELECTED=$(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 |
while IFS= read -r -d '' file; do
    name=$(basename "$file")
    # This exact format comes straight from the Rofi thumbnails docs:
    #   label\0icon\x1fthumbnail://path/to/file
    printf "%s\0icon\x1fthumbnail://%s\n" "$name" "$file"
done |
rofi -dmenu -show-icons -p "Wallpaper" \
     -theme ~/.config/rofi/extras/wallpapers/wallpaper.rasi)

[ -z "$SELECTED" ] && exit

# Find the actual selected path
WALL_PATH="$WALL_DIR/$SELECTED"

# Set wallpaper via awww
awww img "$WALL_PATH" \
    --outputs "$MONITOR" \
    --transition-type center \
    --transition-duration 1 \
    --transition-fps 60
