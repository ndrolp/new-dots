#!/usr/bin/env bash

set -euo pipefail

WALLPAPER_MAIN="$HOME/Pictures/Wallpapers/Current/Horizontal"
WALLPAPER_SECONDARY="$HOME/Pictures/Wallpapers/Current/Vertical"

TRANSITION_TYPE="wipe"
TRANSITION_STEP=120
TRANSITION_FPS=120

MONITORS_JSON=$(hyprctl monitors -j)
AWWW_QUERY=$(awww query)

echo "$MONITORS_JSON" | jq -c '.[]' | while read -r MON; do
    NAME=$(echo "$MON" | jq -r '.name')
    TRANSFORM=$(echo "$MON" | jq -r '.transform')

    # Extract current wallpaper path for this monitor
    CURRENT_WP=$(echo "$AWWW_QUERY" | \
        grep "$NAME:" | \
        sed -E 's/.*image: (.*)$/\1/')

    if [[ -z "$CURRENT_WP" ]]; then
        echo "Could not determine current wallpaper for $NAME"
        continue
    fi

    FILENAME=$(basename "$CURRENT_WP")

    # Select matching orientation
    if [[ "$TRANSFORM" == "1" || "$TRANSFORM" == "3" ]]; then
        WP="$WALLPAPER_SECONDARY/$FILENAME"
    else
        WP="$WALLPAPER_MAIN/$FILENAME"
    fi

    # Fallback if missing
    if [[ ! -f "$WP" ]]; then
        echo "Missing wallpaper: $WP"
        continue
    fi

    echo "Setting wallpaper for $NAME → $WP"

    awww img -o "$NAME" "$WP" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-step "$TRANSITION_STEP" \
        --transition-fps "$TRANSITION_FPS"
done
