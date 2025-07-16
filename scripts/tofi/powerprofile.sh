#!/bin/bash

BALANCED="   Balanced"
TURBO="   Performance"
BATTERY="󰌪   Power Saver"

# Show the menu
QUERY=$(echo -e "${BALANCED}\n${TURBO}\n${BATTERY}" | tofi --prompt-text="Select Power Profile: " --require-match=false)

# If a valid selection was made
if [[ $(echo "$QUERY" | wc -c) -gt 1 ]]; then
    case "$QUERY" in
        "$BALANCED") powerprofilesctl set balanced ;;
        "$TURBO") powerprofilesctl set performance ;;  # fixed typo: performace → performance
        "$BATTERY") powerprofilesctl set power-saver ;;
        *) echo "Unknown selection" ;;
    esac
fi
