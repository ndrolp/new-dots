#!/usr/bin/env bash
# Tests for applying a colorscheme with colorscheme_changer.sh, run through the shared harness
# (colorscheme_changer_harness.sh): a scratch HOME and a PATH shim, logging its calls, for every program
# the changer drives, so the live session is never touched. (This file sits beside the changer rather than
# in a tests/ folder because every folder in colorschemes/ is listed as a colorscheme.)
# Run: colorschemes/colorscheme_changer_tests.sh [name filter]
set -uo pipefail

COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$COLORSCHEMES/colorscheme_changer_harness.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

# Every colorscheme's GTK theme: the bootstrap's list of them (its tests check it names each one).
mapfile -t GTK_THEMES < <(sed 's/#.*//' "$COLORSCHEMES/../common/bootstrap/gtk-themes.txt" | awk 'NF { print $1 }')

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    echo "  calls:"
    sed 's/^/    | /' "$CALLS" 2>/dev/null
    return 1
}

# change_colorscheme [--failing "<tool>..."] <args>...: runs the changer with <args> (see changer_home and
# run_changer in the harness). nvim is the real one, but the changer only sees the nvim sockets in
# $RUN_DIR, and when $NVIM_THEME is set it replaces every colorscheme's nvim/theme.lua.
# $ACTIVE_COLORSCHEME, when set, is made the active colorscheme first. Sets OUT to the changer's output,
# NOTIFICATIONS to the notify-send calls, one per line, and HOME_DIR to the scratch HOME.
change_colorscheme() {
    local theme
    if [[ "$1" == --failing ]]; then
        changer_home --failing "$2"
        shift 2
    else
        changer_home
    fi
    [[ -z "${ACTIVE_COLORSCHEME:-}" ]] || ln -s "$ACTIVE_COLORSCHEME" "$HOME_DIR/.dotfiles/colorschemes/active"
    install_gtk_themes "$HOME_DIR"
    if [[ -n "${NVIM_THEME:-}" ]]; then
        for theme in "$HOME_DIR"/.dotfiles/colorschemes/*/nvim/theme.lua; do
            printf '%s\n' "$NVIM_THEME" >"$theme"
        done
    fi
    run_changer "$@"
    NOTIFICATIONS="$(grep "^notify-send " "$CALLS" || true)"
}

# install_gtk_themes <home>: gives <home> GTK as the desktop has it: every colorscheme's GTK theme in
# ~/.themes (except $MISSING_GTK_THEME, and without a gtk-4.0 folder for $GTK3_ONLY_THEME), a GTK3
# settings.ini holding settings besides the theme, and the GTK4 links pointing at the everforest theme.
install_gtk_themes() {
    local home="$1" theme link
    for theme in "${GTK_THEMES[@]}"; do
        [[ "$theme" == "${MISSING_GTK_THEME:-}" ]] && continue
        mkdir -p "$home/.themes/$theme/gtk-3.0"
        [[ "$theme" == "${GTK3_ONLY_THEME:-}" ]] && continue
        mkdir -p "$home/.themes/$theme/gtk-4.0/assets"
        touch "$home/.themes/$theme/gtk-4.0/"{gtk.css,gtk-dark.css}
    done
    mkdir -p "$home/.config/gtk-3.0" "$home/.config/gtk-4.0"
    printf '[Settings]\ngtk-theme-name=Everforest-Dark\ngtk-icon-theme-name=Papirus-Dark\n' \
        >"$home/.config/gtk-3.0/settings.ini"
    for link in gtk.css gtk-dark.css assets; do
        ln -s "$home/.themes/Everforest-Dark/gtk-4.0/$link" "$home/.config/gtk-4.0/$link"
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

# The nvim/theme.lua every colorscheme gets in these tests: it loads nvim's built-in "desert", standing in
# for the plugin themes.
APPLIED_NVIM_THEME='vim.cmd.colorscheme("desert")'

# commit_dotfiles: makes the scratch ~/.dotfiles a git repo, with the repo's .gitignore, and commits it.
commit_dotfiles() {
    cp "$COLORSCHEMES/../.gitignore" "$HOME_DIR/.dotfiles/.gitignore"
    git -C "$HOME_DIR/.dotfiles" init -q
    git -C "$HOME_DIR/.dotfiles" add -A
    git -C "$HOME_DIR/.dotfiles" -c user.name=t -c user.email=t@t commit -qm dotfiles
}

# The colour links an apply leaves alone, and the default-colorscheme record.
UNCHANGED_BY_APPLY=(
    common/.config/waybar/custom/colors.css
    common/.config/hypr/custom/hyprlock-colors.conf
    common/.config/nvim/lua/settings/core/theme.lua
    common/.config/rofi/custom/colors.rasi
    colorschemes/default.txt
)

test_applying_leaves_the_tracked_colour_links_and_the_default_colorscheme_unchanged() {
    changer_home
    commit_dotfiles
    run_changer everforestdark
    run_changer nord
    [[ -z "$(git -C "$HOME_DIR/.dotfiles" status --porcelain -- "${UNCHANGED_BY_APPLY[@]}")" ]] \
        || fail "git status: $(git -C "$HOME_DIR/.dotfiles" status --porcelain -- "${UNCHANGED_BY_APPLY[@]}")"
}

test_the_colour_links_lead_to_the_applied_colorschemes_colours() {
    change_colorscheme nord
    local app file
    for app in waybar/custom/colors.css:waybar/colors.css hypr/custom/hyprlock-colors.conf:hyprlock/colors.conf \
        nvim/lua/settings/core/theme.lua:nvim/theme.lua rofi/custom/colors.rasi:rofi/colors.rasi; do
        file="$(readlink -f "$HOME_DIR/.config/${app%%:*}")"
        [[ "$file" == "$HOME_DIR/.dotfiles/colorschemes/nord/${app#*:}" ]] || fail "${app%%:*} leads to $file"
    done
}

test_the_active_colorscheme_link_is_gitignored() {
    changer_home
    commit_dotfiles
    run_changer nord
    git -C "$HOME_DIR/.dotfiles" check-ignore -q colorschemes/active || fail "colorschemes/active is not ignored"
}

test_asking_for_the_active_colorscheme_names_it() {
    ACTIVE_COLORSCHEME=kanagawa change_colorscheme --active
    [[ "$OUT" == kanagawa ]] || fail "expected kanagawa"
    [[ ! -s "$CALLS" ]] || fail "asking drove a program"
}

test_without_an_active_link_the_default_colorscheme_becomes_active() {
    changer_home
    echo rosepine >"$HOME_DIR/.dotfiles/colorschemes/default.txt"
    run_changer --active
    [[ "$OUT" == rosepine ]] || fail "expected the default, rosepine"
    [[ "$(readlink "$HOME_DIR/.dotfiles/colorschemes/active")" == rosepine ]] || fail "the active link was not created"
}

test_an_apply_without_an_active_link_leaves_the_default_colorscheme_alone() {
    changer_home
    run_changer nord
    [[ "$(cat "$HOME_DIR/.dotfiles/colorschemes/default.txt")" == everforestdark ]] || fail "default.txt was written"
    [[ "$(readlink "$HOME_DIR/.dotfiles/colorschemes/active")" == nord ]] || fail "nord is not active"
}

test_listing_names_every_colorscheme_but_not_the_active_link() {
    ACTIVE_COLORSCHEME=nord change_colorscheme --list
    [[ "$OUT" == "$(printf '%s\n' bloodmoon carbonfox catppuccin coralnord dracula everforestdark gruvboxdark \
        kanagawa nord rosepine tokyonight)" ]] || fail "unexpected list"
}

test_the_active_link_cannot_be_applied_as_a_colorscheme() {
    ACTIVE_COLORSCHEME=nord change_colorscheme active || true
    [[ "$(readlink "$HOME_DIR/.dotfiles/colorschemes/active")" == nord ]] || fail "the active link was moved"
    [[ ! -s "$CALLS" ]] || fail "applying active drove a program"
}

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

test_applying_leads_quickshells_colours_to_the_colorschemes_and_asks_the_shell_to_reload_them() {
    change_colorscheme nord
    [[ "$(readlink -f "$HOME_DIR/.config/quickshell/config/colors.json")" == "$HOME_DIR/.dotfiles/colorschemes/nord/quickshell/colors.json" ]] \
        || fail "colours do not lead to nord's"
    grep -qx "quickshell ipc --path $HOME_DIR/.config/quickshell call colorscheme reload" "$CALLS" \
        || fail "the shell was not asked to reload its colours"
}

test_applying_does_not_restart_quickshell() {
    change_colorscheme nord
    [[ "$(grep "^quickshell " "$CALLS" | grep -vc "^quickshell ipc ")" -eq 0 ]] \
        || fail "quickshell was run for more than its IPC"
}

test_every_running_nvim_follows_an_applied_colorscheme() {
    trap stop_nvims EXIT
    local first second
    start_nvim
    first="$SOCKET"
    start_nvim
    second="$SOCKET"
    NVIM_THEME="$APPLIED_NVIM_THEME" change_colorscheme nord
    [[ "$(colorscheme_in "$first")" == desert ]] || fail "the first nvim did not follow"
    [[ "$(colorscheme_in "$second")" == desert ]] || fail "the second nvim did not follow"
    [[ -z "$NOTIFICATIONS" ]] || fail "the nvims following notified"
}

test_a_dead_nvim_socket_fails_the_nvim_step_without_stopping_the_other_nvims() {
    trap stop_nvims EXIT
    local alive
    start_nvim
    alive="$SOCKET"
    : >"$RUN_DIR/nvim.1.0"
    NVIM_THEME="$APPLIED_NVIM_THEME" change_colorscheme nord
    [[ "$(colorscheme_in "$alive")" == desert ]] || fail "the live nvim did not follow"
    [[ "$NOTIFICATIONS" == *nvim* ]] || fail "the notification does not name nvim"
}

test_new_nvims_start_in_the_applied_colorscheme() {
    change_colorscheme nord
    [[ "$(readlink -f "$HOME_DIR/.config/nvim/lua/settings/core/theme.lua")" == "$HOME_DIR/.dotfiles/colorschemes/nord/nvim/theme.lua" ]] \
        || fail "theme.lua does not lead to nord's"
}

test_previewing_does_not_change_the_active_colorscheme() {
    ACTIVE_COLORSCHEME=everforestdark change_colorscheme --preview nord
    [[ "$(readlink "$HOME_DIR/.dotfiles/colorschemes/active")" == everforestdark ]] || fail "the active link was moved"
}

test_previewing_then_leaving_the_preview_leaves_git_status_clean() {
    ACTIVE_COLORSCHEME=everforestdark change_colorscheme --active
    commit_dotfiles
    run_changer --preview nord
    run_changer --preview everforestdark
    [[ -z "$(git -C "$HOME_DIR/.dotfiles" status --porcelain)" ]] \
        || fail "git status: $(git -C "$HOME_DIR/.dotfiles" status --porcelain)"
}

test_without_a_shown_link_hyprland_and_quickshell_show_the_active_colorscheme() {
    ACTIVE_COLORSCHEME=kanagawa change_colorscheme --active
    [[ "$(readlink -f "$HOME_DIR/.config/hypr/custom/colors.lua")" == "$HOME_DIR/.dotfiles/colorschemes/kanagawa/hypr/colors.lua" ]] \
        || fail "Hyprland colours do not lead to kanagawa's"
    [[ "$(readlink -f "$HOME_DIR/.config/quickshell/config/colors.json")" == "$HOME_DIR/.dotfiles/colorschemes/kanagawa/quickshell/colors.json" ]] \
        || fail "Quickshell colours do not lead to kanagawa's"
}

test_the_shown_colorscheme_link_is_gitignored() {
    changer_home
    commit_dotfiles
    run_changer --preview nord
    git -C "$HOME_DIR/.dotfiles" check-ignore -q colorschemes/shown || fail "colorschemes/shown is not ignored"
}

test_applying_makes_the_colorscheme_the_active_one() {
    ACTIVE_COLORSCHEME=everforestdark change_colorscheme nord
    [[ "$(readlink "$HOME_DIR/.dotfiles/colorschemes/active")" == nord ]] || fail "the active link does not name nord"
}

test_previewing_recolours_hyprland_and_quickshell() {
    change_colorscheme --preview nord
    [[ "$(readlink -f "$HOME_DIR/.config/hypr/custom/colors.lua")" == "$HOME_DIR/.dotfiles/colorschemes/nord/hypr/colors.lua" ]] \
        || fail "Hyprland colours do not lead to nord's"
    grep -qx "hyprctl reload" "$CALLS" || fail "Hyprland was not reloaded"
    [[ "$(readlink -f "$HOME_DIR/.config/quickshell/config/colors.json")" == "$HOME_DIR/.dotfiles/colorschemes/nord/quickshell/colors.json" ]] \
        || fail "Quickshell colours do not lead to nord's"
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
    [[ "$(readlink "$HOME_DIR/.config/gtk-4.0/gtk.css")" == "$HOME_DIR/.themes/Everforest-Dark/gtk-4.0/gtk.css" ]] \
        || fail "the GTK4 links were touched"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
