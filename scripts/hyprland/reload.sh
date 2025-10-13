#!/bin/bash



monitors=$(hyprctl monitors | grep '^Monitor' | awk '{print $2}')

# if echo "$monitors" | grep -q '^DP-4$'; then
#    hyprctl dispatch moveworkspacetomonitor 1 DP-4
#    hyprctl dispatch moveworkspacetomonitor 2 DP-4
#    hyprctl dispatch moveworkspacetomonitor 3 DP-4
#    hyprctl dispatch moveworkspacetomonitor 4 DP-4
#    hyprctl dispatch moveworkspacetomonitor 5 DP-4
#    hyprctl dispatch moveworkspacetomonitor 6 DP-4
#    hyprctl dispatch moveworkspacetomonitor 7 DP-4
#    hyprctl dispatch moveworkspacetomonitor 8 DP-4
#    hyprctl dispatch moveworkspacetomonitor 9 DP-4
#    hyprctl dispatch moveworkspacetomonitor 10 DP-4
# fi
#
# if echo "$monitors" | grep -q '^DP-5$'; then
#    hyprctl dispatch moveworkspacetomonitor 11 DP-5
#    hyprctl dispatch moveworkspacetomonitor 12 DP-5
#    hyprctl dispatch moveworkspacetomonitor 13 DP-5
#    hyprctl dispatch moveworkspacetomonitor 14 DP-5
#    hyprctl dispatch moveworkspacetomonitor 15 DP-5
#    hyprctl dispatch moveworkspacetomonitor 16 DP-5
#    hyprctl dispatch moveworkspacetomonitor 17 DP-5
#    hyprctl dispatch moveworkspacetomonitor 18 DP-5
#    hyprctl dispatch moveworkspacetomonitor 19 DP-5
#    hyprctl dispatch moveworkspacetomonitor 10 DP-5
# fi
#
# if echo "$monitors" | grep -q '^DP-6$'; then
#    hyprctl dispatch moveworkspacetomonitor 1 DP-6
#    hyprctl dispatch moveworkspacetomonitor 2 DP-6
#    hyprctl dispatch moveworkspacetomonitor 3 DP-6
#    hyprctl dispatch moveworkspacetomonitor 4 DP-6
#    hyprctl dispatch moveworkspacetomonitor 5 DP-6
#    hyprctl dispatch moveworkspacetomonitor 6 DP-6
#    hyprctl dispatch moveworkspacetomonitor 7 DP-6
#    hyprctl dispatch moveworkspacetomonitor 8 DP-6
#    hyprctl dispatch moveworkspacetomonitor 9 DP-6
#    hyprctl dispatch moveworkspacetomonitor 10 DP-6
# fi
#
# if echo "$monitors" | grep -q '^DP-7$'; then
#    hyprctl dispatch moveworkspacetomonitor 11 DP-7
#    hyprctl dispatch moveworkspacetomonitor 12 DP-7
#    hyprctl dispatch moveworkspacetomonitor 13 DP-7
#    hyprctl dispatch moveworkspacetomonitor 14 DP-7
#    hyprctl dispatch moveworkspacetomonitor 15 DP-7
#    hyprctl dispatch moveworkspacetomonitor 16 DP-7
#    hyprctl dispatch moveworkspacetomonitor 17 DP-7
#    hyprctl dispatch moveworkspacetomonitor 18 DP-7
#    hyprctl dispatch moveworkspacetomonitor 19 DP-7
#    hyprctl dispatch moveworkspacetomonitor 10 DP-7
# fi
#
#
main_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.description | contains("271V8")) | .name')
secondary_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.description | contains("243V7")) | .name')


echo "Resolved monitor name: $main_monitor"
echo "Resolved monitor name: $secondary_monitor"


hyprctl dispatch moveworkspacetomonitor 1 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 2 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 3 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 4 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 5 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 6 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 7 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 8 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 9 "$main_monitor"
hyprctl dispatch moveworkspacetomonitor 10 "$main_monitor"

hyprctl dispatch moveworkspacetomonitor 11 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 12 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 13 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 14 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 15 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 16 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 17 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 18 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 19 "$secondary_monitor"
hyprctl dispatch moveworkspacetomonitor 10 "$secondary_monitor"
