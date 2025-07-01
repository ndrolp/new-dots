#!/bin/sh

if tmux has-session -t "main" 2>/dev/null; then
    tmux;
else
    tmux new-session -s "main"
fi

