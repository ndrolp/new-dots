#!/bin/sh
# Personal projects
clear
projects=""
if [ -d ~/Documentos/Projects  ]; then
    projects=`ls ~/Documentos/Projects | tr ' ' '\n'`
fi
# Work Projects
work_projects=""
if [ -d ~/Development/Projects  ]; then
    work_projects=`ls ~/Development/Projects | tr ' ' \n`
fi
# configuration folder
config=`ls ~/.dotfiles/.config | tr ' ' '\n'`
# Prompt
selected=`printf "$projects\n$config\n$work_projects\ndotfiles" | fzf --prompt="󰃖 Go to: " --border`
# Cd to folder
if [ -z "$selected" ]; then
    clear
    return 0
fi

if printf $projects | grep -qs $selected; then
    cd ~/Documentos/Projects/"$selected"/
    clear
    nvim
elif printf $config | grep -qs $selected; then
    cd ~/.dotfiles/.config/"$selected"/
    clear
    nvim
elif printf $work_projects | grep -qs $selected; then
    cd ~/Development/Projects/"$selected"/
    clear
    nvim
else 
    cd ~/.dotfiles
    clear
    nvim
fi

