#!/usr/bin/env bash
# Installs the AUR package groups with paru: core-aur, and apps-aur unless --minimal.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

groups=(core-aur)
[[ "${DOTFILES_MINIMAL:-false}" == true ]] || groups+=(apps-aur)
packages="$(package_list "${groups[@]}")"

info "Installing AUR packages (${groups[*]})..."
paru -S --needed --noconfirm - <<<"$packages"
summary_add installed "AUR packages: ${groups[*]}"
