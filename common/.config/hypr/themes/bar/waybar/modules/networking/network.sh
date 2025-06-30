#!/bin/bash

# Get the active network interface
INTERFACE=$(ip route | grep default | awk '{print $5}')

if [ -z "$INTERFACE" ]; then
    echo "󰱟"
    exit 1
fi

# Check if the interface is wireless
IS_WIRELESS=$(iw dev "$INTERFACE" info 2>/dev/null)

if [ -n "$IS_WIRELESS" ]; then
    # Wireless connection
    SSID=$(iwgetid -r)
    SIGNAL=$(awk '/^\s*w/ { print int($3 * 100 / 70) " %" }' /proc/net/wireless)

    if [ -z "$SSID" ]; then
        echo "󰤭"
    else
        SIGNAL=$(($SIGNAL_RAW * 100 / 70))

        # Determine strength level (1-5)
        if [ "$SIGNAL" -ge 80 ]; then
            STRENGTH="󰤨"
        elif [ "$SIGNAL" -ge 60 ]; then
            STRENGTH="󰤥"
        elif [ "$SIGNAL" -ge 40 ]; then
            STRENGTH="󰤢"
        elif [ "$SIGNAL" -ge 20 ]; then
            STRENGTH="󰤟"
        else
            STRENGTH="󰤯"
        fi

        echo "$STRENGTH"
    fi
else
    # Wired connection
    LINK_STATUS=$(cat /sys/class/net/"$INTERFACE"/carrier 2>/dev/null)

    if [ "$LINK_STATUS" == "1" ]; then
        echo "󰍹"
    else
        echo "󰶐"
    fi
fi
