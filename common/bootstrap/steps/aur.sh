#!/usr/bin/env bash
# Installs the AUR package list with paru.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

pkg_list="$DOTFILES_DIR/common/packages/paru.txt"
[[ -f "$pkg_list" ]] || { error "Package list not found: $pkg_list"; exit 1; }

info "Installing AUR packages..."
paru -S --needed --noconfirm - <"$pkg_list"
summary_add installed "AUR packages from paru.txt"
