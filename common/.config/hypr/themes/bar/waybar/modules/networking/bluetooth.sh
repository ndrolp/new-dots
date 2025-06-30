#!/bin/bash

# Check Bluetooth status
STATUS=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
CONNECTED=$(bluetoothctl info | grep "Connected:" | awk '{print $2}')

if [ "$STATUS" == "no" ]; then
    echo "󰂲"
elif [ "$CONNECTED" == "yes" ]; then
    echo "󰂰"
else
    echo "󰂯"
fi
