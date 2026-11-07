#!/usr/bin/env sh
# Restarts the shell, and starts it if it isn't running. Matching the exact
# command line start.sh runs leaves dev instances on other paths alone.
# Usage: ~/.config/quickshell/restart.sh

running="^quickshell --path $HOME/.config/quickshell\$"

pkill -u "$(id -u)" -f "$running"

# It takes a moment to exit, and start.sh would otherwise bring up a second
# shell beside it. Three seconds in, it's hung and won't go by itself.
tries=0
while pgrep -u "$(id -u)" -f "$running" >/dev/null; do
  tries=$((tries + 1))
  [ "$tries" -ne 30 ] || pkill -KILL -u "$(id -u)" -f "$running"
  sleep 0.1
done

exec "$(dirname "$0")/start.sh"
