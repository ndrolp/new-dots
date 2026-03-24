#!/bin/bash

MONITOR_MAIN="desc:Philips Consumer Electronics Company PHL 271V8 0x0000A8BE"
MONITOR_SECONDARY="desc:Philips Consumer Electronics Company PHL 243V7 0x00009A4C"

# Move workspaces 1–10 to main monitor
for ws in {1..10}; do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_MAIN"
done

# Move workspaces 11–20 to secondary monitor
for ws in {11..20}; do
  hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR_SECONDARY"
done
