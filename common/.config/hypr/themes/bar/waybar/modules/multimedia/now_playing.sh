#!/bin/bash

# Exit with status 1 if no media player is available
if ! playerctl -l &>/dev/null; then
    exit 1
fi

title=$(playerctl metadata --format '{{title}}')
artist=$(playerctl metadata --format '{{artist}}')

# Clip title to 23 characters with ellipsis if needed
max_len=30
if (( ${#title} > max_len )); then
    clipped_title="${title:0:$((max_len-3))}..."
else
    clipped_title="$title"
fi

# Output: Title - Artist
echo "$clipped_title  -  $artist"
