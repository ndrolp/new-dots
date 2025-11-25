#!/bin/sh

killall -q waybar

CONFIG="$HOME/.config/hypr/waybar/waybar.jsonc"
THEME="$HOME/.config/hypr/waybar/style/style.css"


swaync-client --reload-config
swaync-client -rs
waybar --config $CONFIG --style $THEME --log-level debug
# waybar -c ~/.config/hypr/waybar/config.jsonc & -s ~/.config/hypr/waybar/style.css
