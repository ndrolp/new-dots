#!/usr/bin/env sh
# Starts Quickshell following the GTK icon theme. Qt only learns the icon
# theme from a platform theme, so it is passed in through QS_ICON_THEME.
# Stays running as long as the shell does, to step in if it dies while locked.
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

runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
# Has text in it while the session is locked: see components/lock/Lock.qml.
locked_marker=$runtime_dir/quickshell-locked

# What's left of the shell that died, which otherwise goes with the next reboot.
save_what_the_shell_left() {
  saved=${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/lock-failures/$(date +%Y%m%d-%H%M%S)
  mkdir -p "$saved"
  echo "$1" >"$saved/exit-status"
  cp "$runtime_dir/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log" "$saved/" 2>/dev/null
  newest=$(ls -td "$runtime_dir"/quickshell/by-id/*/ 2>/dev/null | head -n 1)
  [ -z "$newest" ] || cp "$newest"log.log "$newest"log.qslog "$saved/" 2>/dev/null
}

# A locked session with no lock screen can't be unlocked, so hyprlock takes over and the shell comes
# back behind it. It stays in the foreground to be here for that. Hyprland needs
# misc:allow_session_lock_restore to let hyprlock in.
while :; do
  quickshell --path "$HOME/.config/quickshell" >/dev/null 2>&1
  status=$?
  [ -s "$locked_marker" ] || exit "$status"
  save_what_the_shell_left "$status"
  hyprlock
  rm -f "$locked_marker"
done
