#!/bin/sh
# Reads what Hyprland left beside the saved file at $1: "unreadable" or "readable", then the monitors in
# `.fallback`. A `.bad` file is news only once, so it's moved aside as it's read: that holds across
# restarts, and a new bad file is news again. Every backup is kept, each under a name of its own.
saved=$1
told=readable

for bad in "$saved.bad" "$saved".bad.[0-9]*; do
    [ -e "$bad" ] || continue
    name="$saved.bad.told"
    number=0
    while [ -e "$name" ]; do
        number=$((number + 1))
        name="$saved.bad.told.$number"
    done
    mv -n -- "$bad" "$name" && told=unreadable
done

echo "$told"
cat -- "$saved.fallback" 2>/dev/null
exit 0
