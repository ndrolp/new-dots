#!/usr/bin/env bash
# Installs nvm (in ~/.nvm, or in $NVM_DIR when an nvm is already there) and the latest LTS node.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

NVM_INSTALLER="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
# An inherited NVM_DIR with no nvm in it (e.g. ~/.config/nvm from an old shell) does not count.
[[ -s "${NVM_DIR:-}/nvm.sh" ]] || NVM_DIR="$HOME/.nvm"
export NVM_DIR

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

# run_nvm <args>: nvm.sh and its function are not written for set -eu, so they run without it.
run_nvm() {
    local status=0
    set +eu
    nvm "$@" || status=$?
    set -eu
    return "$status"
}

set +eu
source "$NVM_DIR/nvm.sh"
set -eu

lts="$(run_nvm version 'lts/*' || true)"
if [[ -n "$lts" && "$lts" != N/A ]]; then
    info "node $lts (LTS) already installed."
    summary_add skipped "node LTS (already installed: $lts)"
else
    info "Installing the latest LTS node..."
    run_nvm install --lts
    summary_add installed "node $(run_nvm version 'lts/*') (LTS)"
fi
