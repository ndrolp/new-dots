#!/usr/bin/env sh
# Starts Quickshell following the GTK icon theme. Qt only learns the icon
# theme from a platform theme, so it is passed in through QS_ICON_THEME.
# Usage: ~/.config/quickshell/start.sh

# The colour links lead through the machine-local links colorschemes/active
# and shown, which a clone only has once something creates them. Asking the
# changer for the active colorscheme creates any that are missing (and does
# nothing else), so a pull that brings in new colour links needs no
# bootstrap. ~/.config/quickshell is a stow link into the repo, and ".."
# resolves through it. A failure here must not keep the shell from starting.
"$(dirname "$0")/../../../colorschemes/colorscheme_changer.sh" --active >/dev/null || true

icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
if [ -n "$icon_theme" ]; then
  export QS_ICON_THEME="$icon_theme"
fi
exec quickshell --path "$HOME/.config/quickshell" --daemonize
