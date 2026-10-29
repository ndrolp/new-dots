#!/usr/bin/env bash
# Sets the stable Rust toolchain (paru and many AUR packages build with cargo), then builds
# and installs paru from the AUR unless it is already there.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

rustup default stable

if command -v paru >/dev/null 2>&1; then
    info "paru is already installed."
    summary_add skipped "paru (already installed)"
    exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

info "Cloning paru into $tmp_dir..."
git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
info "Building and installing paru..."
(cd "$tmp_dir/paru" && makepkg -si --noconfirm)
summary_add installed paru
