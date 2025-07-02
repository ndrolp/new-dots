#!/bin/bash

color=$(hyprpicker)

if [ -n "$color" ]; then
    echo "$color" | wl-copy
    notify-send "Color Picker" "Color ${color} copied to clipboard"
fi
