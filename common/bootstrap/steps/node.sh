#!/usr/bin/env bash
# Installs nvm (in $NVM_DIR, default ~/.nvm) and the latest LTS node.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

NVM_INSTALLER="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    info "nvm already installed."
    summary_add skipped "nvm (already installed)"
else
    mkdir -p "$NVM_DIR"
    installer="$(curl -fsSL "$NVM_INSTALLER")"
    info "Installing nvm into $NVM_DIR..."
    # PROFILE=/dev/null: the stowed .zshrc already loads nvm, so no shell file is edited.
    PROFILE=/dev/null bash -c "$installer"
    summary_add installed nvm
fi

# nvm.sh is not written for set -eu.
set +eu
source "$NVM_DIR/nvm.sh"
lts="$(nvm version 'lts/*')"
if [[ -n "$lts" && "$lts" != N/A ]]; then
    info "node $lts (LTS) already installed."
    summary_add skipped "node LTS (already installed: $lts)"
else
    info "Installing the latest LTS node..."
    nvm install --lts || exit 1
    summary_add installed "node $(nvm version 'lts/*') (LTS)"
fi
