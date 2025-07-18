#!/bin/bash

choice=$(yad --width=600 --height=100 --title="Modo de energía" --button="⚖ Balanced:1" --button="🚀 Performance:2" --button="🪫 Power Saver:3" --no-click-to-dismiss --center)

case $? in
  1)
    powerprofilesctl set balanced
    notify-send "Modo de energía" "⚖ Balanced activado"
    ;;
  2)
    powerprofilesctl set performance
    notify-send "Modo de energía" "🚀 Performance activado"
    ;;
  3)
    powerprofilesctl set power-saver
    notify-send "Modo de energía" "🪫 Power Saver activado"
    ;;
  *)
    exit 1
    ;;
esac
