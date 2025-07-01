#!/bin/bash

folder=$(xdg-user-dir PICTURES)
echo "$folder"

mkdir -p "${folder}/Screenshots"

filename="${folder}/Screenshots/screenshot_$(date +'%Y-%m-%d-%H%M%S').png"

if slurp | grim -g - "$filename" && wl-copy --type image/png < "$filename"; then
    notify-send "Screenshot" "Screenshot saved and copied to clipboard" -i "$filename"
fi
