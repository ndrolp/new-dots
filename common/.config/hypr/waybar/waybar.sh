#!/bin/sh

killall -q waybar

CONFIG="$HOME/.config/hypr/waybar/config.jsonc"
THEME="$HOME/.config/hypr/waybar/style.css"

waybar --config $CONFIG --style $THEME --log-level debug
# waybar -c ~/.config/hypr/waybar/config.jsonc & -s ~/.config/hypr/waybar/style.css
