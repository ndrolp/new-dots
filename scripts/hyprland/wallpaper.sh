#!/usr/bin/env bash

WALLPAPER_MAIN="$HOME/Pictures/Wallpapers"
WALLPAPER_SECONDARY="$HOME/Pictures/Wallpapers Vertical"

# Get monitor info
MONITORS_JSON=$(hyprctl monitors -j)

pick_random() {
    find "$1" -type f | shuf -n 1
}

echo "$MONITORS_JSON" | jq -c '.[]' | while read -r MON; do
    NAME=$(echo "$MON" | jq -r '.name')
    TRANSFORM=$(echo "$MON" | jq -r '.transform')

    # Decide wallpaper and mode based on rotation
    if [[ "$TRANSFORM" == "1" || "$TRANSFORM" == "3" ]]; then
        WP=$(pick_random "$WALLPAPER_SECONDARY")
        MODE="contain"
    else
        WP=$(pick_random "$WALLPAPER_MAIN")
        MODE="fill"
    fi

    echo "$NAME"
    # Set wallpaper for this monitor
    swww img "$WP" --outputs "$NAME"
done
