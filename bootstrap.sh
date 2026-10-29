#!/usr/bin/env bash
# Sets up this machine from the dotfiles repo. Run ./bootstrap.sh --help for the flags.
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

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_SUMMARY_FILE="$(mktemp)"
export DOTFILES_DIR DOTFILES_HOST DOTFILES_MINIMAL DOTFILES_STOW_ONLY DOTFILES_NO_SYSTEM DOTFILES_SPICETIFY DOTFILES_SUMMARY_FILE
source "$DOTFILES_DIR/common/bootstrap/lib.sh"

log_dir="$HOME/.local/state/dotfiles"
mkdir -p "$log_dir"
DOTFILES_LOG_FILE="$log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$DOTFILES_LOG_FILE") 2>&1
trap 'print_summary; rm -f "$DOTFILES_SUMMARY_FILE"' EXIT

if [[ "$DOTFILES_STOW_ONLY" == true ]]; then
    steps=(stow)
else
    steps=(packages paru aur shell node)
    [[ "$DOTFILES_SPICETIFY" == true ]] && steps+=(spicetify)
    steps+=(stow)
fi

for step in "${steps[@]}"; do
    run_step "$step"
done
