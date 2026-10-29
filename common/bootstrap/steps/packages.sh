#!/usr/bin/env bash
# Updates the system and installs the pacman package list.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

pkg_list="$DOTFILES_DIR/common/packages/pacman.txt"
[[ -f "$pkg_list" ]] || { error "Package list not found: $pkg_list"; exit 1; }

info "Updating the system..."
sudo pacman -Syu --noconfirm
info "Installing pacman packages..."
sudo pacman -S --needed --noconfirm - <"$pkg_list"
summary_add installed "pacman packages from pacman.txt"
