#!/usr/bin/env bash

# Kill existing instances of the apps
pkill -f "kitty.*--class cava"
pkill -f "kitty.*--class ncmpcpp"
pkill -f "kitty.*--class clock"

# Switch to workspace 11 and set master layout
# hyprctl dispatch workspace 11
hyprctl dispatch layout master

# Launch applications
kitty --class cava -e cava &
sleep 0.3
kitty --class ncmpcpp -e spotify_player &
sleep 0.3
kitty --class clock -e peaclock &
sleep 0.3

# Give windows a moment to spawn
sleep 1

# Resize and arrange windows
hyprctl dispatch focuswindow class:cava
hyprctl dispatch resizeactive exact 75% 100%

hyprctl dispatch focuswindow class:clock
hyprctl dispatch resizeactive exact 20% 70%

hyprctl dispatch focuswindow class:ncmpcpp
hyprctl dispatch sendkey L

hyprctl dispatch layout dwindle
