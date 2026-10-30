#!/usr/bin/env bash
# Sets up this machine from the dotfiles repo. Run ./bootstrap.sh --help for the flags.
# Everything runs from main, called on the last line, so a download cut short runs nothing.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [options]

  --host <name>   Use host-<name> instead of the machine's hostname
  --minimal       Skip the apps package group
  --stow-only     Only link the config files (skip installing anything)
  --no-system     Skip enabling services and changing the login shell
  --spicetify     Also install spicetify
  --help          Show this help
EOF
}

# Run outside a clone (curl ... | bash), the script clones the repo to ~/.dotfiles and
# re-runs itself from there. DOTFILES_REPO_URL overrides where it clones from (for tests).
DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/ndrolp/new-dots.git}"
DOTFILES_SSH_URL="git@github.com:ndrolp/new-dots.git"

# start_log: copies everything the run prints into the log file, through tee. The run from the
# clone gets DOTFILES_LOG_FILE and appends to the same log as the clone stage before it.
start_log() {
    local log_dir="$HOME/.local/state/dotfiles"
    mkdir -p "$log_dir"
    DOTFILES_LOG_FILE="${DOTFILES_LOG_FILE:-$log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log}"
    export DOTFILES_LOG_FILE
    exec 3>&1 4>&2
    exec > >(tee -a "$DOTFILES_LOG_FILE") 2>&1
    tee_pid=$!
}

# stop_log: points the output back at the terminal and waits (up to 5s, in case something
# left running still holds the pipe) for tee to write out what it has.
stop_log() {
    [[ -n "${tee_pid:-}" ]] || return 0
    exec 1>&3 2>&4 3>&- 4>&-
    local i state
    for ((i = 0; i < 50; i++)); do
        # Gone, or a zombie: tee has written everything out.
        state="$(cut -d' ' -f3 "/proc/$tee_pid/stat" 2>/dev/null || true)"
        [[ -n "$state" && "$state" != Z ]] || break
        sleep 0.1
    done
    tee_pid=""
}

clone_and_reexec() {
    local clone_dir="$HOME/.dotfiles"
    if ! command -v git >/dev/null 2>&1; then
        echo "Installing git..."
        sudo pacman -S --needed --noconfirm git
    fi
    if [[ -d "$clone_dir/.git" ]]; then
        echo "Updating the existing clone in $clone_dir..."
        git -C "$clone_dir" pull --ff-only "$DOTFILES_REPO_URL" \
            || echo "warning: could not update $clone_dir, running it as it is" >&2
    elif [[ -e "$clone_dir" ]]; then
        echo "$clone_dir exists but is not a git clone; move it away and run again." >&2
        exit 1
    else
        echo "Cloning $DOTFILES_REPO_URL into $clone_dir..."
        git clone --recurse-submodules "$DOTFILES_REPO_URL" "$clone_dir"
    fi
    git -C "$clone_dir" remote set-url origin "$DOTFILES_SSH_URL"
    echo "origin is now $DOTFILES_SSH_URL: add an SSH key to GitHub before you push."
    stop_log
    trap - EXIT
    # Under curl | bash stdin is the rest of the download: give the run the terminal instead.
    if (: </dev/tty) 2>/dev/null; then
        exec bash "$clone_dir/bootstrap.sh" "$@" </dev/tty
    else
        exec bash "$clone_dir/bootstrap.sh" "$@" </dev/null
    fi
}

# on_exit: prints the summary (once the run has one), stops the sudo keep-alive, removes the
# run's temp files and lets tee finish writing before the script exits.
on_exit() {
    if [[ -n "${DOTFILES_RUN_DIR:-}" ]]; then
        stop_keepalive
        print_summary
        rm -rf "$DOTFILES_RUN_DIR"
    fi
    stop_log
}

main() {
    DOTFILES_ARGS=("$@")

    DOTFILES_HOST=""
    DOTFILES_MINIMAL=false
    DOTFILES_STOW_ONLY=false
    DOTFILES_NO_SYSTEM=false
    DOTFILES_SPICETIFY=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --host)
                [[ $# -ge 2 ]] || { echo "--host needs a name" >&2; exit 2; }
                DOTFILES_HOST="$2"
                shift
                ;;
            --minimal) DOTFILES_MINIMAL=true ;;
            --stow-only) DOTFILES_STOW_ONLY=true ;;
            --no-system) DOTFILES_NO_SYSTEM=true ;;
            --spicetify) DOTFILES_SPICETIFY=true ;;
            --help | -h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done

    if [[ "$(id -u)" -eq 0 ]]; then
        echo "Do not run bootstrap.sh as root; run it as your user, it asks for sudo when it needs it." >&2
        exit 1
    fi

    trap on_exit EXIT
    start_log

    local self="${BASH_SOURCE[0]:-}"
    if [[ -z "$self" || ! -f "$(dirname "$self")/common/bootstrap/lib.sh" ]]; then
        clone_and_reexec "${DOTFILES_ARGS[@]}"
    fi

    DOTFILES_DIR="$(cd "$(dirname "$self")" && pwd -P)"
    source "$DOTFILES_DIR/common/bootstrap/lib.sh"
    DOTFILES_RUN_DIR="$(mktemp -d)"
    DOTFILES_SUMMARY_FILE="$DOTFILES_RUN_DIR/summary"
    DOTFILES_KEEPALIVE_PID_FILE="$DOTFILES_RUN_DIR/keepalive.pid"
    : >"$DOTFILES_SUMMARY_FILE"
    export DOTFILES_DIR DOTFILES_HOST DOTFILES_MINIMAL DOTFILES_STOW_ONLY DOTFILES_NO_SYSTEM DOTFILES_SPICETIFY \
        DOTFILES_SUMMARY_FILE DOTFILES_KEEPALIVE_PID_FILE

    local steps step
    if [[ "$DOTFILES_STOW_ONLY" == true ]]; then
        steps=(stow)
    else
        steps=(preflight packages paru aur hardware shell node)
        # Building GTK themes needs sassc, from the apps group.
        [[ "$DOTFILES_MINIMAL" == true ]] || steps+=(gtk-themes)
        [[ "$DOTFILES_SPICETIFY" == true ]] && steps+=(spicetify)
        steps+=(stow)
        steps+=(services)
    fi

    for step in "${steps[@]}"; do
        run_step "$step"
    done
}

main "$@"
