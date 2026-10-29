#!/usr/bin/env bash
# Links common/ and, when it exists, host-<host>/ into $HOME.
# Files in the way are moved to ~/.dotfiles-backup/<timestamp>/ first; never --adopt.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# conflicts <package>: the targets (relative to $HOME) stow would refuse to replace,
# one per line. Matches the messages of stow 2.4 and 2.3.
conflicts() {
    stow -n -v -d "$DOTFILES_DIR" -t "$HOME" "$1" 2>&1 | sed -n \
        -e 's/^  \* cannot stow .* over existing target \(.*\) since neither a link nor a directory.*/\1/p' \
        -e 's/^  \* existing target is neither a link nor a directory: \(.*\)/\1/p' || true
}

# stow_package <package>: backs up what is in the way, then stows <package>.
stow_package() {
    local target
    while IFS= read -r target; do
        [[ -n "$target" ]] || continue
        mkdir -p "$(dirname "$backup_dir/$target")"
        mv "$HOME/$target" "$backup_dir/$target"
        info "Moved ~/$target to $backup_dir/$target"
        summary_add backed-up "~/$target -> $backup_dir/$target"
    done < <(conflicts "$1")
    if ! has_changes "$1"; then
        info "$1 is already linked."
        summary_add skipped "stow: $1 (already linked)"
        return 0
    fi
    stow -v -d "$DOTFILES_DIR" -t "$HOME" "$1"
    summary_add installed "stow: $1"
}

# has_changes <package>: whether stow would create or remove any link or dir for <package>.
# A dry run that fails counts as a change, so the real stow runs and reports the error.
has_changes() {
    local plan
    plan="$(stow -n -v -d "$DOTFILES_DIR" -t "$HOME" "$1" 2>&1)" || return 0
    grep -qE '^(LINK|UNLINK|MKDIR|RMDIR):' <<<"$plan"
}

stow_package common

host="$(dotfiles_host)"
if [[ -d "$DOTFILES_DIR/host-$host" ]]; then
    info "Stowing host-specific dotfiles for $host..."
    stow_package "host-$host"
else
    info "Note: no host-$host dir, stowed common only."
    summary_add skipped "stow: no host-$host dir"
fi
