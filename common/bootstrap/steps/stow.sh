#!/usr/bin/env bash
# Links common/ and, when it exists, host-<host>/ into $HOME.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

stow -v -d "$DOTFILES_DIR" -t "$HOME" common
summary_add installed "stow: common"

host="$(dotfiles_host)"
if [[ -d "$DOTFILES_DIR/host-$host" ]]; then
    info "Stowing host-specific dotfiles for $host..."
    stow -v -d "$DOTFILES_DIR" -t "$HOME" "host-$host"
    summary_add installed "stow: host-$host"
else
    info "No host-$host dir, stowed common only."
    summary_add skipped "stow: no host-$host dir"
fi
