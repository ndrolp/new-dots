#!/bin/bash

# Get the default audio sink
SINK=$(wpctl get-default Sink)

# Get volume and mute status
VOLUME=$(wpctl get-volume "$SINK" | awk '{print int($2 * 100)}')
MUTED=$(wpctl get-volume "$SINK" | grep -o "MUTED")

if [ "$MUTED" = "MUTED" ]; then
    notify-send -a volume -h string:x-canonical-private-synchronous:volume "Volume Muted"
else
    notify-send -a volume -h string:x-canonical-private-synchronous:volume "Volume: $VOLUME%"
fi
