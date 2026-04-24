#!/bin/bash

# $HOME/.config/waybar/waybar.sh

MONITOR_MAIN="desc:Philips Consumer Electronics Company PHL 271V8 0x0000A8BE"
MONITOR_SECONDARY="desc:HKC OVERSEAS LIMITED E2212F 0000000000001"

# Move workspaces 1–10 to main monitor
for ws in {1..10}; do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_MAIN"
done

# Move workspaces 11–20 to secondary monitor
for ws in {11..20}; do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_SECONDARY"
done

$HOME/.config/ags/reload.sh
