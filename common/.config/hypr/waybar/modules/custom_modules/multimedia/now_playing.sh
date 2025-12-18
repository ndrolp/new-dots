#!/bin/bash

# List players
players=$(playerctl -l 2>/dev/null)

# If no players detected, output nothing
if [[ -z "$players" ]]; then
    exit 0
fi

# Prefer Spotify, fallback to first player
if echo "$players" | grep -q spotify; then
    player="spotify"
else
    player=$(echo "$players" | head -n 1)
fi

# Try to read metadata; suppress errors
title=$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null)
artist=$(playerctl -p "$player" metadata --format '{{artist}}' 2>/dev/null)

# If no title returned (stopped or no metadata), output nothing
if [[ -z "$title" ]]; then
    echo ""
    exit 0
fi

# Clip title to 30 characters with ellipsis
max_len=30
if (( ${#title} > max_len )); then
    clipped_title="${title:0:$((max_len-3))}..."
else
    clipped_title="$title"
fi

# Final safeguard: empty clipped title
if [[ -z "$clipped_title" ]]; then
    # echo ""
    # echo "FUA"
    exit 0
fi

# Output: Title - Artist
echo "$clipped_title  -  $artist"
