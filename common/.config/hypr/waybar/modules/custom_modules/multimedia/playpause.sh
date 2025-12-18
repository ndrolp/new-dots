#!/bin/bash

# -----------------------------
# Icon dictionary (apps only)
# -----------------------------
declare -A ICONS=(
    ["firefox"]=""
    ["chrome"]=""
    ["vlc"]="󰕼"
    ["mpv"]=""
    ["nvim"]=""
)

DEFAULT_ICON="󰣆"

# -----------------------------
# Helpers
# -----------------------------
match_icon() {
    local text="$1"
    for key in "${!ICONS[@]}"; do
        if [[ "$text" =~ $key ]]; then
            echo "${ICONS[$key]}"
            return
        fi
    done
    echo "$DEFAULT_ICON"
}

get_focused_title() {
    # Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl activewindow -j 2>/dev/null \
        | jq -r '(.class // "") + " " + (.title // "")'
        return
    fi

    # Sway / wlroots
    if command -v swaymsg >/dev/null 2>&1; then
        swaymsg -t get_tree 2>/dev/null \
        | jq -r '.. | select(.focused? == true) | (.app_id // "") + " " + (.name // "")'
        return
    fi

    # KDE Wayland
    if command -v qdbus >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin activeWindowTitle 2>/dev/null
        return
    fi

    # GNOME Wayland → blocked
    echo ""
}

# -----------------------------
# Media detection (controls only)
# -----------------------------
players=$(playerctl -l 2>/dev/null)

if [[ -n "$players" ]]; then
    if echo "$players" | grep -qi spotify; then
        player="spotify"
    else
        player=$(echo "$players" | head -n 1)
    fi

    status=$(playerctl -p "$player" status 2>/dev/null || true)

    case "$status" in
        Playing)
            echo ""
            exit 0
            ;;
        Paused)
            echo ""
            exit 0
            ;;
    esac
fi

# -----------------------------
# Fallback: focused app icon
# -----------------------------
focused=$(get_focused_title)

# No focused window → show nothing
[[ -z "$focused" ]] && echo "" && exit 0

# Focused window exists → match or default
echo "$(match_icon "$focused")"
exit 0
