#!/usr/bin/env bash

# CMDs
uptime_info=$(uptime -p | sed -e 's/up //g')
host=$(hostnamectl hostname)

# Options with Icons and Text
options=("Balanced" "Power Saver" "Performance")
icons=("" "󰜉" "")

# Rofi CMD
rofi_cmd() {
    options_with_icons=()
    for ((i = 0; i < ${#options[@]}; i++)); do
        options_with_icons+=("${icons[$i]}")
    done

    printf "%s\n" "${options_with_icons[@]}" | \
    rofi -dmenu -no-config-warnings -i -p " $USER@$host" \
        -kb-select-1 "p" \
        -kb-select-2 "r" \
        -kb-select-3 "l" \
        -theme ~/.config/rofi/extras/powermenu/powermenu.rasi | awk '{print $1}'
}

# Execute Command
run_cmd() {
    echo $1
    case $1 in
        "")
            shutdown now
            ;;
        "󰜉")
            reboot
            ;;
        "")
            hyprctl dispatch exit
            ;;
    esac
}

# Actions
chosen_option=$(rofi_cmd)
run_cmd "${chosen_option% *}"
