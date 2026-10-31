# Shared by the tests that run colorscheme_changer.sh (colorschemes/colorscheme_changer_tests.sh and
# common/.config/hypr/tests/borders.sh); source it, don't run it. The changer runs against a scratch HOME
# holding a copy of the colorschemes, and every program it drives is a PATH shim, so the live session is
# never touched. (It sits beside the changer rather than in a folder because every folder in colorschemes/
# is listed as a colorscheme.) Needs SCRATCH, a scratch folder the caller removes.

CHANGER_HARNESS_COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGER_HARNESS_REPO="$(cd "$CHANGER_HARNESS_COLORSCHEMES/.." && pwd)"

# The repo's colour links, as tracked under common/.config, and kitty's config, which includes one.
CHANGER_HARNESS_COLOUR_LINKS=(
    waybar/custom/colors.css
    hypr/custom/colors.conf
    hypr/custom/colors.lua
    hypr/custom/hyprlock-colors.conf
    nvim/lua/settings/core/theme.lua
    rofi/custom/colors.rasi
    quickshell/config/colors.json
    kitty/colorscheme.conf
    kitty/kitty.conf
)

# changer_home [--failing "<tool>..."]: makes a scratch HOME laid out as stow leaves it: ~/.dotfiles holds
# a copy of the colorschemes (with no active colorscheme) and the repo's colour links under
# common/.config, and each ~/.config/<app> links to its common/.config/<app>. Also a shim for every
# program the changer drives that logs "<tool> <args>" to $CALLS; the --failing ones also exit 1. A test
# may replace a shim in $HOME_DIR/bin before run_changer. Sets HOME_DIR and CALLS.
changer_home() {
    local failing="" bin tool link app
    if [[ "${1:-}" == --failing ]]; then
        failing="$2"
    fi
    HOME_DIR="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$HOME_DIR/bin"
    mkdir -p "$HOME_DIR/.dotfiles" "$bin" "$HOME_DIR/run" "$HOME_DIR/.config"
    cp -r "$CHANGER_HARNESS_COLORSCHEMES" "$HOME_DIR/.dotfiles/colorschemes"
    rm -f "$HOME_DIR/.dotfiles/colorschemes/active"
    for link in "${CHANGER_HARNESS_COLOUR_LINKS[@]}"; do
        mkdir -p "$(dirname "$HOME_DIR/.dotfiles/common/.config/$link")"
        cp -P "$CHANGER_HARNESS_REPO/common/.config/$link" "$HOME_DIR/.dotfiles/common/.config/$link"
    done
    for app in hypr waybar rofi nvim quickshell kitty; do
        ln -s "../.dotfiles/common/.config/$app" "$HOME_DIR/.config/$app"
    done
    for tool in hyprctl pkill ags quickshell gsettings rofi node notify-send; do
        cat >"$bin/$tool" <<SHIM
#!/bin/sh
echo "$tool \$*" >>"\$HOME/calls"
case " $failing " in *" $tool "*) exit 1 ;; esac
exit 0
SHIM
    done
    chmod +x "$bin"/*
    CALLS="$HOME_DIR/calls"
    : >"$CALLS"
}

# run_changer <args>...: runs the changer copied into $HOME_DIR with <args>, with the shims first on PATH.
# The changer only sees the nvim sockets in $RUN_DIR (default: an empty folder). Sets OUT to its output.
run_changer() {
    OUT="$(HOME="$HOME_DIR" XDG_RUNTIME_DIR="${RUN_DIR:-$HOME_DIR/run}" PATH="$HOME_DIR/bin:$PATH" \
        bash "$HOME_DIR/.dotfiles/colorschemes/colorscheme_changer.sh" "$@" 2>&1)"
}
