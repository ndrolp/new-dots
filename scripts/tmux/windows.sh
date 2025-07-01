#!/bin/sh

# Get the list of windows in the current session
windows=$(tmux list-windows)

prompt="  Switch Window: "
color="prompt:blue"

if [ "$1" = "--kill" ]; then
    prompt="  Kill Window: "
    color="prompt:yellow"
fi

# Select a window using fzf
selected=$(printf "$windows" | fzf --prompt="$prompt" --layout="reverse" --no-sort --color="$color" --exact)
window_name=$(echo "$selected" | cut -d':' -f1)

# If no window was selected, exit
if [ -z "$selected" ]; then
    clear
    return 0
fi

# If the --kill option is passed, kill the selected window
if [ "$1" = "--kill" ]; then
    tmux kill-window -t "$window_name"
else
    tmux select-window -t "$window_name"
fi
