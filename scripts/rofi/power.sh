#!/bin/bash

SHUTDOWN="⏻    Poweroff"
REBOOT="    Reboot"
LOGOUT="     Logout"


QUERY=$(echo -e "\
${LOGOUT}\n\
${REBOOT}\n\
${SHUTDOWN}" | wofi -i --dmenu --prompt "" --height 185 --width 240 -b)

CON=$(echo $QUERY | tr " " "+" )


if [[ $(echo $CON | wc -c) -gt 1 ]]
then
    case $QUERY in 
    $LOGOUT ) hyprctl dispatch exit; ;;
    $REBOOT ) reboot; ;;
    $SHUTDOWN ) poweroff; ;;
    * ) echo "NO SELECTED"
    esac
fi
