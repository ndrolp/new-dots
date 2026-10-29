#!/usr/bin/env bash
# Installs oh-my-zsh and the plugins and theme the .zshrc loads. Runs before stow.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

OH_MY_ZSH_INSTALLER="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
# Where the .zshrc looks for custom plugins and themes.
zsh_custom="${ZSH_CUSTOM:-$HOME/.config/zsh_custom}"

install_oh_my_zsh() {
    if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        info "oh-my-zsh already installed."
        summary_add skipped "oh-my-zsh (already installed)"
        return 0
    fi
    local had_zshrc=false installer
    [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]] && had_zshrc=true
    installer="$(curl -fsSL "$OH_MY_ZSH_INSTALLER")"
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$installer" "" --unattended
    # With no .zshrc the installer writes its template; drop it so stow links ours.
    [[ "$had_zshrc" == true ]] || rm -f "$HOME/.zshrc"
    summary_add installed oh-my-zsh
}

# clone_once <name> <url> <dir>: clones <url> into <dir> unless it is already there.
clone_once() {
    local name="$1" url="$2" dir="$3"
    if [[ -d "$dir" ]]; then
        info "$name already installed."
        summary_add skipped "$name (already installed)"
    else
        git clone --depth=1 "$url" "$dir"
        summary_add installed "$name"
    fi
}

# Through sudo so chsh does not ask for the password again.
change_login_shell() {
    local user login_shell zsh_path
    user="$(id -un)"
    login_shell="$(getent passwd "$user" | cut -d: -f7)"
    if [[ "$(basename "$login_shell")" == zsh ]]; then
        info "The login shell is already zsh."
        summary_add skipped "chsh (login shell is already zsh)"
    elif system_changes_allowed "chsh to zsh"; then
        # The path listed in /etc/shells: chsh refuses others, and PATH may find /usr/sbin/zsh first.
        zsh_path="$(grep -m1 '/zsh$' /etc/shells 2>/dev/null || command -v zsh)"
        info "Changing the login shell to $zsh_path..."
        sudo chsh -s "$zsh_path" "$user"
        summary_add installed "login shell: zsh"
    fi
}

install_oh_my_zsh
clone_once zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
clone_once zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
clone_once "spaceship theme" https://github.com/spaceship-prompt/spaceship-prompt.git "$zsh_custom/themes/spaceship-prompt"
ln -sfn "$zsh_custom/themes/spaceship-prompt/spaceship.zsh-theme" "$zsh_custom/themes/spaceship.zsh-theme"
change_login_shell
