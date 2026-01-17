#!/bin/bash

MAX_LEN=50

clip() {
    local text="$1"
    if (( ${#text} > MAX_LEN )); then
        echo "${text:0:$((MAX_LEN-3))}..."
    else
        echo "$text"
    fi
}

get_focused_title() {
    # Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl activewindow -j 2>/dev/null | jq -r '.title // empty'
        return
    fi

    # Sway / wlroots
    if command -v swaymsg >/dev/null 2>&1; then
        swaymsg -t get_tree 2>/dev/null \
        | jq -r '.. | select(.focused? == true) | .name // empty'
        return
    fi

    # KDE Wayland
    if command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin activeWindowTitle 2>/dev/null
        return
    fi

    # GNOME Wayland → intentionally empty (security restriction)
    echo ""
}

# -----------------------------
# Media detection
# -----------------------------
players=$(playerctl -l 2>/dev/null)

if echo "$players" | grep -q spotify; then
    player="spotify"
else
    player=$(echo "$players" | head -n 1)
fi

title=""
artist=""

if [[ -n "$player" ]]; then
    title=$(playerctl -p "$player" metadata --format '{{title}}' 2>/dev/null)
    artist=$(playerctl -p "$player" metadata --format '{{artist}}' 2>/dev/null)
fi

# -----------------------------
# Output logic
# -----------------------------
if [[ -n "$title" ]]; then
    title=$(clip "$title")
    echo "$title  -  $artist"
    exit 0
fi

focused_title=$(get_focused_title)

if [[ -n "$focused_title" ]]; then
    echo "$(clip "$focused_title")"
fi

exit 0
