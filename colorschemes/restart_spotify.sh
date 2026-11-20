#!/usr/bin/env bash
# restart_spotify.sh [--resume]: restarts the running Spotify so it shows the colours spicetify just
# refreshed (Spotify only reads them when it starts). With --resume, playback is resumed once the new
# Spotify is up. The colorscheme changer runs it detached, so applying never waits for Spotify.
# (A live reload would need Spotify's remote debugging port open, which any local web page could use.)
set -uo pipefail

resume=false
[[ "${1:-}" == --resume ]] && resume=true

running() { pgrep -x -u "$(id -u)" spotify >/dev/null; }

pkill -x -u "$(id -u)" spotify
# Spotify saves its state on the way out; wait for it rather than starting a second one.
for ((i = 0; i < 100; i++)); do
    running || break
    sleep 0.1
done
if running; then
    echo "restart_spotify.sh: Spotify did not exit" >&2
    exit 1
fi

# Started by Hyprland, so it gets the compositor's environment and outlives this script. Hyprland's
# config is Lua, so dispatch takes a Lua dispatcher.
if ! hyprctl dispatch 'hl.dsp.exec_cmd("spotify")' >/dev/null; then
    echo "restart_spotify.sh: Hyprland did not start Spotify" >&2
    exit 1
fi

[[ "$resume" == true ]] || exit 0
# Spotify restores the last track paused; play once it answers on MPRIS.
for ((i = 0; i < 150; i++)); do
    if playerctl -p spotify status >/dev/null 2>&1; then
        sleep 1
        playerctl -p spotify play
        exit 0
    fi
    sleep 0.2
done
echo "restart_spotify.sh: Spotify did not come back on MPRIS" >&2
exit 1
