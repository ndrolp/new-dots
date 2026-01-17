#!/bin/sh

killall -q waybar

CONFIG="$HOME/.config/waybar/waybar.jsonc"
THEME="$HOME/.config/waybar/custom/layouts/style.css"


swaync-client --reload-config
swaync-client -rs
waybar --config $CONFIG --style $THEME --log-level debug
# waybar -c ~/.config/hypr/waybar/config.jsonc & -s ~/.config/hypr/waybar/style.css

# Monitor descriptions (must match hyprctl monitors output exactly)
