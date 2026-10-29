#!/usr/bin/env bash
# Clones the zsh plugins the .zshrc loads.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_plugin() {
    local name="$1" url="$2"
    if [[ -d "$zsh_custom/plugins/$name" ]]; then
        info "$name already installed."
        summary_add skipped "$name (already installed)"
    else
        git clone "$url" "$zsh_custom/plugins/$name"
        summary_add installed "$name"
    fi
}

clone_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
