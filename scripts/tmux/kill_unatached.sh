!#/bin/sh

tmux ls | grep '(attached)' -v | awk '{print $1}' | xargs -I {} tmux kill-session -t {}
