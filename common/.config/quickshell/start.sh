#!/usr/bin/env sh
# Starts Quickshell following the GTK icon theme. Qt only learns the icon
# theme from a platform theme, so it is passed in through QS_ICON_THEME.
# Usage: ~/.config/quickshell/start.sh
icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
if [ -n "$icon_theme" ]; then
  export QS_ICON_THEME="$icon_theme"
fi
exec quickshell --path "$HOME/.config/quickshell" --daemonize
