#!/bin/bash

# Map: description -> sink name
declare -A sink_map

# Build the menu list with only descriptions
menu=""
while read -r line; do
    sink_name=$(echo "$line" | awk '{print $2}')
    desc=$(pactl list sinks | grep -A20 "Name: $sink_name" | grep "Description:" | head -n1 | cut -d ':' -f2- | sed 's/^ //')
    
    if [[ -n "$desc" ]]; then
        sink_map["$desc"]="$sink_name"
        menu+="$desc\n"
    fi
done < <(pactl list short sinks)

# Show the menu with wofi
selection=$(echo -e "$menu" | rofi -dmenu -prompt "Select Audio Output" -no-show-icons -i -columns 1 -theme ~/.config/rofi/extras/audio_selector/audio_selector.rasi)

# Set the selected sink as default and move streams
if [[ -n "$selection" ]]; then
    selected_sink="${sink_map[$selection]}"
    pactl set-default-sink "$selected_sink"
    
    # Move playing streams to the new sink
    pactl list short sink-inputs | while read -r input; do
        input_id=$(echo "$input" | awk '{print $1}')
        echo "Moving input $input_id to sink $selected_sink"
        pactl move-sink-input "$input_id" "$selected_sink"
    done
fi
