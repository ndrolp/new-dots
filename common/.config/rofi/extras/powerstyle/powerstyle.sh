#!/usr/bin/env bash

# CMDs
uptime_info=$(uptime -p | sed -e 's/up //g')
host=$(hostnamectl hostname)

# Options with Icons and Text
options=("Balanced" "Power Saver" "Performance")
icons=("" "󰌪" "")

# Rofi CMD
rofi_cmd() {
    options_with_icons=()
    for ((i = 0; i < ${#options[@]}; i++)); do
        options_with_icons+=("${icons[$i]}")
    done

    printf "%s\n" "${options_with_icons[@]}" | \
    rofi -dmenu -no-config-warnings -i -p " $USER@$host" \
        -kb-select-1 "b" \
        -kb-select-2 "e" \
        -kb-select-3 "p" \
        -theme ~/.config/rofi/extras/powerstyle/powerstyle.rasi | awk '{print $1}'
}

# Execute Command
run_cmd() {
    echo $1
    case $1 in
        "")
            powerprofilesctl set balanced
            notify-send --app-name="Power Profile" "⚖️ Balanced Mode" "You are now using the Balanced power profile."
            ;;
        "󰌪")
            powerprofilesctl set power-saver
            notify-send --app-name="Power Profile" "🍃 Power Saver Mode" "Battery life is now prioritized."
            ;;
        "")
            powerprofilesctl set performance
            notify-send --app-name="Power Profile" "🚀 Performance Mode" "Maximum performance enabled."
            ;;
    esac
}

# Actions
chosen_option=$(rofi_cmd)
run_cmd "${chosen_option% *}"
