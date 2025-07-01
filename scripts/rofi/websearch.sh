#!/bin/bash

killall wofi
# Define options with icons
GITHUB="   Github"
YOUTUBE="    Youtube"
NERD_FONT="    NerdFont"
ANIME_FLV="󰿎    Anime FLV"
WALLHAVEN="󰋩   Wallhaven"
CHATGPT="󰭻    ChatGPT"
GMAIL="󰊫     Gmail"
NETFLIX="󰝆     Netflix"


# Get default browser
BROWSER=$(xdg-settings get default-web-browser)

# Display the Rofi menu and capture the selected option
QUERY=$(echo -e "\
${YOUTUBE}\n\
${GITHUB}\n\
${NERD_FONT}\n\
${ANIME_FLV}\n\
${WALLHAVEN}\n\
${CHATGPT}\n\
${NETFLIX}\n\
${GMAIL}" | wofi -i --dmenu --prompt "" -b)

# Replace spaces with + for URL encoding
CON=$(echo "$QUERY" | tr " " "+")

# Open the corresponding URL based on the selection
if [[ $(echo "$CON" | wc -c) -gt 1 ]]; then
    case $QUERY in 
        "$NERD_FONT" ) xdg-open https://www.nerdfonts.com/cheat-sheet ;;
        "$ANIME_FLV" ) xdg-open https://www3.animeflv.net/ ;;
        "$WALLHAVEN" ) xdg-open https://wallhaven.cc/ ;;
        "$GMAIL" ) xdg-open https://mail.google.com/ ;;
        "$YOUTUBE" ) xdg-open https://youtube.com ;;
        "$CHATGPT" ) xdg-open https://chatgpt.com ;;
        "$GITHUB" ) xdg-open https://github.com/ ;;
        "$NETFLIX" ) xdg-open https://www.netflix.com/ ;;
        * ) xdg-open "https://www.google.com/search?q=$CON" ;;
    esac
fi

