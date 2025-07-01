#!/bin/bash

SHUTDOWN="⏻ Poweroff"
REBOOT=" Reboot"
LOGOUT=" Logout"


QUERY=$(echo -e "\
${LOGOUT}\n\
${REBOOT}\n\
${SHUTDOWN}\n\
" | dmenu -p " ⭘  " -fn "Hasklug Nerd Font-9" -h 28 -i -sb '#f5a97f')

CON=$(echo $QUERY | tr " " "+" )


if [[ $(echo $CON | wc -c) -gt 1 ]]
then
    case $QUERY in 
    $LOGOUT ) i3 exit; ;;
    $REBOOT ) reboot; ;;
    $SHUTDOWN ) poweroff; ;;
    * ) echo "NO SELECTED"
    esac
fi
