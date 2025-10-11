#!/usr/bin/env bash

# Kill any lingering wofi instance (optional)
killall wofi 2>/dev/null

# Host info
host=$(hostnamectl hostname)

# Options (labels)
options=("Github" "Youtube" "Nerd Font" "Anime FLV" "Wallhaven" "ChatGPT" "Netflix" "Gmail")
# Icons (these can be Nerd Font or any Pango span)
icons=("" "" "" "" "" "󰭹" "󰝆" "󰊫")

# URLs corresponding to each option
urls=(
    "https://github.com/"
    "https://youtube.com"
    "https://www.nerdfonts.com/cheat-sheet"
    "https://www3.animeflv.net/"
    "https://wallhaven.cc/"
    "https://chatgpt.com"
    "https://www.netflix.com/"
    "https://mail.google.com/"
)

# Rofi menu builder using metadata for icons
rofi_cmd() {
    for ((i = 0; i < ${#options[@]}; i++)); do
        echo -en "${options[$i]}\0icon\x1f<span color='#c6d0f5'>${icons[$i]}</span>\n"
    done | \
    rofi -dmenu -i -p "" \
         -theme ~/.config/rofi/extras/quickweb/quickweb.rasi \
         -markup-rows
}

# Execute Command
run_cmd() {
    local choice="$1"
    for ((i = 0; i < ${#options[@]}; i++)); do
        if [[ "$choice" == "${options[$i]}" ]]; then
            xdg-open "${urls[$i]}" &
            return
        fi
    done

    # Fallback: Google search
    search=$(echo "$choice" | tr " " "+")
    xdg-open "https://www.google.com/search?q=$search" &
    notify-send "🔎 Searching on Google" "$choice"
}

# Run
chosen_option=$(rofi_cmd)
[[ -n "$chosen_option" ]] && run_cmd "$chosen_option"
