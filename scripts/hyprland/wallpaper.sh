#!/usr/bin/env bash

WALLPAPER_MAIN="$HOME/Pictures/Wallpapers/Current/Horizontal/"
WALLPAPER_SECONDARY="$HOME/Pictures/Wallpapers/Current/Vertical/"

# Transition settings (optional, tweak to taste)
TRANSITION_TYPE="center"
TRANSITION_STEP=60
TRANSITION_FPS=60

# Get monitor info
MONITORS_JSON=$(hyprctl monitors -j)

pick_random() {
    find "$1" -type f | shuf -n 1
}

echo "$MONITORS_JSON" | jq -c '.[]' | while read -r MON; do
    NAME=$(echo "$MON" | jq -r '.name')
    TRANSFORM=$(echo "$MON" | jq -r '.transform')

    # Decide wallpaper based on rotation
    if [[ "$TRANSFORM" == "1" || "$TRANSFORM" == "3" ]]; then
        WP=$(pick_random "$WALLPAPER_SECONDARY")
    else
        WP=$(pick_random "$WALLPAPER_MAIN")
    fi

    echo "Setting wallpaper for $NAME → $WP"

    awww img -o "$NAME" "$WP" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-step "$TRANSITION_STEP" \
        --transition-fps "$TRANSITION_FPS"
done
