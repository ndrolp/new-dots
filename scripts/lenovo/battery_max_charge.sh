#!/usr/bin/env bash

# Lenovo IdeaPad conservation mode toggle script
# Usage:
#   ./battery_mode.sh on      -> enable 80% max charge
#   ./battery_mode.sh off     -> disable max charge (full 100%)
#   ./battery_mode.sh status  -> show current mode

CONSERVATION_FILE="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

if [ ! -f "$CONSERVATION_FILE" ]; then
    echo "Error: conservation mode file not found."
    exit 1
fi

case "$1" in
    on)
        echo 1 | sudo tee "$CONSERVATION_FILE" >/dev/null
        echo "Conservation mode enabled (max charge ~80%)"
        ;;
    off)
        echo 0 | sudo tee "$CONSERVATION_FILE" >/dev/null
        echo "Conservation mode disabled (full charge 100%)"
        ;;
    status|"")
        STATUS=$(cat "$CONSERVATION_FILE")
        if [ "$STATUS" = "1" ]; then
            echo "Conservation mode is ON (max charge ~80%)"
        else
            echo "Conservation mode is OFF (full charge 100%)"
        fi
        ;;
    *)
        echo "Usage: $0 [on|off|status]"
        exit 1
        ;;
esac
