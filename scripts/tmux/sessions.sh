#!/bin/sh

sessions=`tmux ls`

prompt="  Switch Session: "
color="prompt:blue"

if [ "$1" = "--kill" ]; then
    prompt="  Kill Session: "
    color="prompt:yellow"
fi

selected=`printf "$sessions" | fzf --prompt="$prompt" --layout="reverse" --no-sort --color="$color" --exact`
session_name=`echo "$selected" | cut -d':' -f1`

if [ -z "$selected" ]; then
    clear
    return 0
fi


if [ "$1" = "--kill" ]; then
  tmux kill-session -t "$session_name"
else
  tmux switch-client -t "$session_name"
fi

