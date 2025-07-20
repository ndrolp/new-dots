#!/bin/bash

# Kill any lingering wofi instance (optional)
killall wofi 2>/dev/null

# Define options (each on its own line)
GITHUB="   Github"
YOUTUBE="   Youtube"
NERD_FONT="   NerdFont"
ANIME_FLV="   Anime FLV"
WALLHAVEN="   Wallhaven"
CHATGPT="󰭹   ChatGPT"
GMAIL="󰊫   Gmail"
NETFLIX="󰝆   Netflix"

# Display the Rofi menu and capture the selected option
QUERY=$(echo -e "\
${YOUTUBE}\n\
${GITHUB}\n\
${NERD_FONT}\n\
${ANIME_FLV}\n\
${WALLHAVEN}\n\
${CHATGPT}\n\
${NETFLIX}\n\
${GMAIL}" | rofi -dmenu -i -p "Open site:" -no-show-icons)

# Replace spaces with + for fallback Google search
CON=$(echo "$QUERY" | tr " " "+")

# Open the corresponding URL
if [[ -n "$QUERY" ]]; then
    case $QUERY in 
        "$NERD_FONT") xdg-open https://www.nerdfonts.com/cheat-sheet ;;
        "$ANIME_FLV") xdg-open https://www3.animeflv.net/ ;;
        "$WALLHAVEN") xdg-open https://wallhaven.cc/ ;;
        "$GMAIL") xdg-open https://mail.google.com/ ;;
        "$YOUTUBE") xdg-open https://youtube.com ;;
        "$CHATGPT") xdg-open https://chatgpt.com ;;
        "$GITHUB") xdg-open https://github.com/ ;;
        "$NETFLIX") xdg-open https://www.netflix.com/ ;;
        *) xdg-open "https://www.google.com/search?q=$CON" ;;
    esac
fi
