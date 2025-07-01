#!/bin/zsh

values=`~/.tmuxifier/bin/tmuxifier ls`
selected=`printf "$values" | fzf --prompt="󰣞 Edit: " --ignore-case` 
~/.tmuxifier/bin/tmuxifier edit-session $selected
