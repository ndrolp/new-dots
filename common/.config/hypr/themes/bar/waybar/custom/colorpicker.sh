#!/bin/bash

color=$(hyprpicker)

notify-send "Color Picker" "Color ${color} copied to clipboard"

echo "$color" | wl-copy
