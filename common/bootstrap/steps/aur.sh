#!/usr/bin/env bash
# Installs the AUR package groups, core-aur and apps-aur unless --minimal, one package at a
# time with paru. A package that fails is listed as failed in the summary and the rest go on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

groups=(core-aur)
[[ "${DOTFILES_MINIMAL:-false}" == true ]] || groups+=(apps-aur)
mapfile -t packages < <(package_list "${groups[@]}")

info "Installing AUR packages (${groups[*]})..."
already=0
failed=0
for pkg in "${packages[@]}"; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
        already=$((already + 1))
    elif paru -S --needed --noconfirm "$pkg"; then
        summary_add installed "AUR: $pkg"
    else
        warn "Could not install $pkg from the AUR, going on with the rest."
        summary_add failed "AUR: $pkg"
        failed=$((failed + 1))
    fi
done
((already == 0)) || summary_add skipped "$already AUR packages (already installed)"
((failed == 0)) || warn "$failed AUR packages failed; they are listed in the summary."
