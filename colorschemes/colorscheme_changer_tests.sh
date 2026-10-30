#!/usr/bin/env bash
# Tests for applying a colorscheme with colorscheme_changer.sh. The changer runs against a scratch HOME
# holding a copy of the colorschemes, and every program it drives is a PATH shim that logs its calls, so
# the live session is never touched. (This file sits beside the changer rather than in a tests/ folder
# because every folder in colorschemes/ is listed as a colorscheme.)
# Run: colorschemes/colorscheme_changer_tests.sh [name filter]
set -uo pipefail

COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    echo "  calls:"
    sed 's/^/    | /' "$CALLS" 2>/dev/null
    return 1
}

# change_colorscheme [--failing "<tool>..."] <args>...: runs the changer with <args>. Every program it
# drives is a shim that logs "<tool> <args>" to $CALLS; the --failing ones also exit 1. Sets OUT to the
# changer's output and NOTIFICATIONS to the notify-send calls, one per line.
change_colorscheme() {
    local failing="" home bin tool
    if [[ "$1" == --failing ]]; then
        failing="$2"
        shift 2
    fi
    home="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$home/bin"
    mkdir -p "$home/.dotfiles" "$bin" "$home/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$COLORSCHEMES" "$home/.dotfiles/colorschemes"
    install_gtk_themes "$home"
    for tool in hyprctl kitten ags quickshell gsettings rofi node setsid notify-send; do
        cat >"$bin/$tool" <<SHIM
#!/bin/sh
echo "$tool \$*" >>"\$HOME/calls"
case " $failing " in *" $tool "*) exit 1 ;; esac
exit 0
SHIM
    done
    chmod +x "$bin"/*
    HOME_DIR="$home"
    CALLS="$home/calls"
    : >"$CALLS"
    OUT="$(HOME="$home" PATH="$bin:$PATH" bash "$home/.dotfiles/colorschemes/colorscheme_changer.sh" "$@" 2>&1)"
    NOTIFICATIONS="$(grep "^notify-send " "$CALLS" || true)"
}

# install_gtk_themes <home>: gives <home> GTK as the desktop has it: every colorscheme's GTK theme in
# ~/.themes (except $MISSING_GTK_THEME), a GTK3 settings.ini holding settings besides the theme, and the
# GTK4 links pointing at the everforest theme.
install_gtk_themes() {
    local home="$1" theme dir link
    for theme in $(sed -n 's/.*gtk-theme "\(.*\)".*/\1/p' "$COLORSCHEMES"/*/gtk/colors.sh); do
        [[ "$theme" == "${MISSING_GTK_THEME:-}" ]] && continue
        for dir in gtk-3.0 gtk-4.0/assets; do mkdir -p "$home/.themes/$theme/$dir"; done
        touch "$home/.themes/$theme/gtk-4.0/"{gtk.css,gtk-dark.css}
    done
    mkdir -p "$home/.config/gtk-3.0" "$home/.config/gtk-4.0"
    printf '[Settings]\ngtk-theme-name=Everforest-B-MB-Dark\ngtk-icon-theme-name=Papirus-Dark\n' \
        >"$home/.config/gtk-3.0/settings.ini"
    for link in gtk.css gtk-dark.css assets; do
        ln -s "$home/.themes/Everforest-B-MB-Dark/gtk-4.0/$link" "$home/.config/gtk-4.0/$link"
    done
}

calls_to() { grep -c "^$1 " "$CALLS" || true; }

test_a_failing_step_does_not_stop_the_later_steps() {
    change_colorscheme --failing "kitten" nord
    [[ "$(calls_to quickshell)" -gt 0 ]] || fail "quickshell was never restarted after kitty failed"
}

test_an_apply_with_failed_steps_sends_one_notification_naming_them() {
    change_colorscheme --failing "kitten gsettings" nord
    [[ "$(calls_to notify-send)" -eq 1 ]] || fail "expected exactly one notification"
    [[ "$NOTIFICATIONS" == *kitty* && "$NOTIFICATIONS" == *gtk* ]] || fail "notification does not name kitty and gtk"
    [[ "$NOTIFICATIONS" != *hyprland* ]] || fail "notification names a step that succeeded"
}

test_a_successful_apply_sends_no_notification() {
    change_colorscheme nord
    [[ -z "$NOTIFICATIONS" ]] || fail "a successful apply notified"
}

test_applying_does_not_ask_ags_for_the_theme() {
    change_colorscheme nord
    [[ "$(calls_to ags)" -eq 0 ]] || fail "ags was called"
}

test_previewing_only_reloads_hyprland() {
    change_colorscheme --preview nord
    [[ "$(cut -d' ' -f1 "$CALLS")" == hyprctl ]] || fail "preview drove more than hyprctl"
}

test_a_failing_preview_sends_no_notification() {
    change_colorscheme --failing hyprctl --preview nord
    [[ -z "$NOTIFICATIONS" ]] || fail "a preview notified"
}

test_applying_names_the_gtk_theme_in_gsettings_and_gtk3_settings() {
    change_colorscheme nord
    grep -qx "gsettings set org.gnome.desktop.interface gtk-theme Nordic-darker" "$CALLS" \
        || fail "gsettings gtk-theme was not set to Nordic-darker"
    grep -qx "gtk-theme-name=Nordic-darker" "$HOME_DIR/.config/gtk-3.0/settings.ini" \
        || fail "GTK3 settings.ini does not name Nordic-darker"
    grep -qx "gtk-icon-theme-name=Papirus-Dark" "$HOME_DIR/.config/gtk-3.0/settings.ini" \
        || fail "GTK3 settings.ini lost its other settings"
}

test_applying_points_the_gtk4_links_at_the_gtk_theme() {
    change_colorscheme nord
    local link
    for link in gtk.css gtk-dark.css assets; do
        [[ "$(readlink "$HOME_DIR/.config/gtk-4.0/$link")" == "$HOME_DIR/.themes/Nordic-darker/gtk-4.0/$link" ]] \
            || fail "GTK4 $link does not point at Nordic-darker"
    done
}

test_applying_prefers_dark() {
    change_colorscheme nord
    grep -qx "gsettings set org.gnome.desktop.interface color-scheme prefer-dark" "$CALLS" \
        || fail "color-scheme was not set to prefer-dark"
}

test_applying_does_not_write_a_placeholder_theme_into_gtk4_settings() {
    change_colorscheme nord
    ! grep -qs "THEME_NAME" "$HOME_DIR/.config/gtk-4.0/settings.ini" || fail "GTK4 settings.ini got THEME_NAME"
}

test_a_missing_gtk_theme_fails_the_gtk_step() {
    MISSING_GTK_THEME=Nordic-darker change_colorscheme nord
    [[ "$NOTIFICATIONS" == *gtk* ]] || fail "the gtk step did not fail"
    [[ -e "$HOME_DIR/.config/gtk-4.0/gtk.css" ]] || fail "GTK4 gtk.css was pointed at the missing theme"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
