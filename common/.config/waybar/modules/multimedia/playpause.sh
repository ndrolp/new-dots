#!/bin/bash

# Exit if no player is available
if ! playerctl -l &>/dev/null; then
    exit 1
fi

status=$(playerctl status 2>/dev/null)

if [[ "$status" == "Playing" ]]; then
    echo " "
elif [[ "$status" == "Paused" ]]; then
    echo " "
else
    echo " "
fi
