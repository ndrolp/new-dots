# Shared by the tests that run colorscheme_changer.sh (colorschemes/colorscheme_changer_tests.sh and
# common/.config/hypr/tests/borders.sh); source it, don't run it. The changer runs against a scratch HOME
# holding a copy of the colorschemes, and every program it drives is a PATH shim, so the live session is
# never touched. (It sits beside the changer rather than in a folder because every folder in colorschemes/
# is listed as a colorscheme.) Needs SCRATCH, a scratch folder the caller removes.

CHANGER_HARNESS_COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# changer_home [--failing "<tool>..."]: makes a scratch HOME with the config folders the changer links
# into and a copy of the colorschemes, and a shim for every program the changer drives that logs
# "<tool> <args>" to $CALLS; the --failing ones also exit 1. A test may replace a shim in $HOME_DIR/bin
# before run_changer. Sets HOME_DIR and CALLS.
changer_home() {
    local failing="" bin tool
    if [[ "${1:-}" == --failing ]]; then
        failing="$2"
    fi
    HOME_DIR="$(mktemp -d "$SCRATCH/home.XXXX")"
    bin="$HOME_DIR/bin"
    mkdir -p "$HOME_DIR/.dotfiles" "$bin" "$HOME_DIR/run" \
        "$HOME_DIR/.config/"{hypr/custom,waybar/custom,rofi/custom,nvim/lua/settings/core,quickshell/config}
    cp -r "$CHANGER_HARNESS_COLORSCHEMES" "$HOME_DIR/.dotfiles/colorschemes"
    for tool in hyprctl kitten ags quickshell gsettings rofi node notify-send; do
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
