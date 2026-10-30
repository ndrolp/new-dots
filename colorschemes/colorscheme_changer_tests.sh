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
# drives is a shim that logs "<tool> <args>" to $CALLS; the --failing ones also exit 1. nvim is the real
# one, but the changer only sees the nvim sockets in $RUN_DIR (default: an empty folder), and when
# $NVIM_THEME is set it replaces every colorscheme's nvim/theme.lua. $ACTIVE_COLORSCHEME, when set, is
# written to theme.txt first. Sets OUT to the changer's output,
# NOTIFICATIONS to the notify-send calls, one per line, and HOME_DIR to the scratch HOME.
change_colorscheme() {
    local failing="" home bin tool theme
    if [[ "$1" == --failing ]]; then
        failing="$2"
        shift 2
    fi
    home="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$home/bin"
    mkdir -p "$home/.dotfiles" "$bin" "$home/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$COLORSCHEMES" "$home/.dotfiles/colorschemes"
    [[ -z "${ACTIVE_COLORSCHEME:-}" ]] || echo "$ACTIVE_COLORSCHEME" >"$home/.dotfiles/colorschemes/theme.txt"
    install_gtk_themes "$home"
    if [[ -n "${NVIM_THEME:-}" ]]; then
        for theme in "$home"/.dotfiles/colorschemes/*/nvim/theme.lua; do
            printf '%s\n' "$NVIM_THEME" >"$theme"
        done
    fi
    mkdir -p "$home/run"
    for tool in hyprctl kitten ags quickshell gsettings rofi node setsid notify-send; do
        cat >"$bin/$tool" <<SHIM
#!/bin/sh
echo "$tool \$*" >>"\$HOME/calls"
case " $failing " in *" $tool "*) exit 1 ;; esac
exit 0
SHIM
    done
    chmod +x "$bin"/*
    CALLS="$home/calls"
    : >"$CALLS"
    HOME_DIR="$home"
    OUT="$(HOME="$home" XDG_RUNTIME_DIR="${RUN_DIR:-$home/run}" PATH="$bin:$PATH" bash "$home/.dotfiles/colorschemes/colorscheme_changer.sh" "$@" 2>&1)"
    NOTIFICATIONS="$(grep "^notify-send " "$CALLS" || true)"
}

# install_gtk_themes <home>: gives <home> GTK as the desktop has it: every colorscheme's GTK theme in
# ~/.themes (except $MISSING_GTK_THEME, and without a gtk-4.0 folder for $GTK3_ONLY_THEME), a GTK3 settings.ini holding settings besides the theme, and the
# GTK4 links pointing at the everforest theme.
install_gtk_themes() {
    local home="$1" theme dir link
    for theme in $(sed -n 's/.*gtk-theme "\(.*\)".*/\1/p' "$COLORSCHEMES"/*/gtk/colors.sh); do
        [[ "$theme" == "${MISSING_GTK_THEME:-}" ]] && continue
        mkdir -p "$home/.themes/$theme/gtk-3.0"
        [[ "$theme" == "${GTK3_ONLY_THEME:-}" ]] && continue
        mkdir -p "$home/.themes/$theme/gtk-4.0/assets"
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

# start_nvim: starts a headless nvim listening on a socket in $RUN_DIR (created on first use) and sets
# SOCKET to it. Every nvim started this way is stopped when the test ends.
start_nvim() {
    local socket
    [[ -n "${RUN_DIR:-}" ]] || RUN_DIR="$(mktemp -d "$SCRATCH/run.XXXX")"
    socket="$RUN_DIR/nvim.$RANDOM$RANDOM.0"
    nvim --clean --headless --listen "$socket" </dev/null >/dev/null 2>&1 &
    NVIM_PIDS+=("$!")
    for _ in $(seq 50); do
        [[ -S "$socket" ]] && break
        sleep 0.1
    done
    SOCKET="$socket"
}
NVIM_PIDS=()
stop_nvims() { [[ ${#NVIM_PIDS[@]} -eq 0 ]] || kill "${NVIM_PIDS[@]}" 2>/dev/null; }

# colorscheme_in <socket>: the colorscheme name the nvim on <socket> is using.
colorscheme_in() { nvim --server "$1" --remote-expr 'get(g:, "colors_name", "")'; }

# A built-in colorscheme each nvim is switched to, standing in for the plugin colorschemes.
SWITCHED_THEME='vim.cmd.colorscheme("desert")'

test_a_failing_step_does_not_stop_the_later_steps() {
    change_colorscheme --failing "kitten" nord
    [[ "$(calls_to quickshell)" -gt 0 ]] || fail "quickshell was never asked to reload after kitty failed"
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

test_applying_links_the_colorschemes_quickshell_colours_and_asks_the_shell_to_reload_them() {
    change_colorscheme nord
    [[ "$(readlink "$HOME_DIR/.config/quickshell/config/colors.json")" == "$HOME_DIR/.dotfiles/colorschemes/nord/quickshell/colors.json" ]] \
        || fail "colours not linked"
    grep -qx "quickshell ipc --path $HOME_DIR/.config/quickshell call colorscheme reload" "$CALLS" \
        || fail "the shell was not asked to reload its colours"
}

test_applying_does_not_restart_quickshell() {
    change_colorscheme nord
    ! grep -q "^quickshell kill\|^setsid " "$CALLS" || fail "quickshell was restarted"
}

test_applying_switches_every_running_nvim_to_the_colorscheme() {
    trap stop_nvims EXIT
    local first second
    start_nvim
    first="$SOCKET"
    start_nvim
    second="$SOCKET"
    NVIM_THEME="$SWITCHED_THEME" change_colorscheme nord
    [[ "$(colorscheme_in "$first")" == desert ]] || fail "the first nvim did not switch"
    [[ "$(colorscheme_in "$second")" == desert ]] || fail "the second nvim did not switch"
    [[ -z "$NOTIFICATIONS" ]] || fail "switching the nvims notified"
}

test_a_dead_nvim_socket_fails_the_nvim_step_without_stopping_the_other_nvims() {
    trap stop_nvims EXIT
    local alive
    start_nvim
    alive="$SOCKET"
    : >"$RUN_DIR/nvim.1.0"
    NVIM_THEME="$SWITCHED_THEME" change_colorscheme nord
    [[ "$(colorscheme_in "$alive")" == desert ]] || fail "the live nvim did not switch"
    [[ "$NOTIFICATIONS" == *nvim* ]] || fail "the notification does not name nvim"
}

test_new_nvims_start_in_the_applied_colorscheme() {
    change_colorscheme nord
    [[ "$(readlink "$HOME_DIR/.config/nvim/lua/settings/core/theme.lua")" == "$HOME_DIR/.dotfiles/colorschemes/nord/nvim/theme.lua" ]] \
        || fail "theme.lua does not link to nord's"
}

test_previewing_does_not_change_the_active_colorscheme() {
    ACTIVE_COLORSCHEME=everforestdark change_colorscheme --preview nord
    [[ "$(cat "$HOME_DIR/.dotfiles/colorschemes/theme.txt")" == everforestdark ]] || fail "theme.txt was written"
}

test_applying_makes_the_colorscheme_the_active_one() {
    ACTIVE_COLORSCHEME=everforestdark change_colorscheme nord
    [[ "$(cat "$HOME_DIR/.dotfiles/colorschemes/theme.txt")" == nord ]] || fail "theme.txt does not name nord"
}

test_previewing_recolours_hyprland_and_quickshell() {
    change_colorscheme --preview nord
    [[ "$(readlink "$HOME_DIR/.config/hypr/custom/colors.lua")" == "$HOME_DIR/.dotfiles/colorschemes/nord/hypr/colors.lua" ]] \
        || fail "Hyprland colours not linked"
    grep -qx "hyprctl reload" "$CALLS" || fail "Hyprland was not reloaded"
    [[ "$(readlink "$HOME_DIR/.config/quickshell/config/colors.json")" == "$HOME_DIR/.dotfiles/colorschemes/nord/quickshell/colors.json" ]] \
        || fail "Quickshell colours not linked"
    grep -qx "quickshell ipc --path $HOME_DIR/.config/quickshell call colorscheme reload" "$CALLS" \
        || fail "the shell was not asked to reload its colours"
}

test_previewing_drives_only_hyprland_and_quickshell() {
    change_colorscheme --preview nord
    [[ "$(cut -d' ' -f1 "$CALLS" | sort -u | tr '\n' ' ')" == "hyprctl quickshell " ]] \
        || fail "preview drove more than hyprctl and quickshell"
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

test_a_gtk_theme_without_gtk4_still_applies_gtk3_and_fails_the_gtk_step() {
    GTK3_ONLY_THEME=Nordic-darker change_colorscheme nord
    grep -qx "gsettings set org.gnome.desktop.interface gtk-theme Nordic-darker" "$CALLS" \
        || fail "gsettings gtk-theme was not set to Nordic-darker"
    grep -qx "gsettings set org.gnome.desktop.interface color-scheme prefer-dark" "$CALLS" \
        || fail "color-scheme was not set to prefer-dark"
    grep -qx "gtk-theme-name=Nordic-darker" "$HOME_DIR/.config/gtk-3.0/settings.ini" \
        || fail "GTK3 settings.ini does not name Nordic-darker"
    [[ "$NOTIFICATIONS" == *gtk* ]] || fail "the gtk step did not fail"
    [[ "$(readlink "$HOME_DIR/.config/gtk-4.0/gtk.css")" == "$HOME_DIR/.themes/Everforest-B-MB-Dark/gtk-4.0/gtk.css" ]] \
        || fail "the GTK4 links were touched"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
