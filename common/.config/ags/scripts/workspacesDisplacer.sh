#!/usr/bin/env bash

MONITOR="$1"
START="$2"
END="$3"

for ((ws=START; ws<=END; ws++)); do
    hyprctl dispatch moveworkspacetomonitor "$ws" "$MONITOR"
done
