#!/usr/bin/env bash
# Builds and installs paru from the AUR unless it is already there, setting the stable Rust
# toolchain first (paru builds with cargo).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if command -v paru >/dev/null 2>&1; then
    info "paru is already installed."
    summary_add skipped "paru (already installed)"
    exit 0
fi

rustup default stable

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

info "Cloning paru into $tmp_dir..."
git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru"
info "Building and installing paru..."
(cd "$tmp_dir/paru" && makepkg -si --noconfirm)
summary_add installed paru
