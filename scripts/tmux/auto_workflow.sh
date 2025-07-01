#!/bin/zsh

values=`~/.tmuxifier/bin/tmuxifier ls`
selected=`printf "$values" | fzf --prompt=" Launch: " --ignore-case` 
~/.tmuxifier/bin/tmuxifier load-session $selected

