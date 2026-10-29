#!/usr/bin/env bash
# Updates the system and installs the official-repo package groups, core and apps unless
# --minimal, in one pacman batch. A failed batch fails the step.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

groups=(core)
[[ "${DOTFILES_MINIMAL:-false}" == true ]] || groups+=(apps)
mapfile -t packages < <(package_list "${groups[@]}")

info "Updating the system..."
sudo pacman -Syu --noconfirm
info "Installing pacman packages (${groups[*]})..."
pacman_install "pacman packages: ${groups[*]}" "${packages[@]}"
