#!/usr/bin/env bash
# Installs spicetify and its marketplace into the installed Spotify, themes it with the Dotfiles theme
# (Spotify in the active colorscheme's colours) and applies them. Opt-in with --spicetify.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# DOTFILES_SPOTIFY_DIR points at another Spotify install (for tests).
spotify_dir="${DOTFILES_SPOTIFY_DIR:-/opt/spotify}"
spicetify_dir="$HOME/.spicetify"
spicetify_config="${SPICETIFY_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/spicetify}"
# Where the marketplace installer puts it.
marketplace_dir="$spicetify_config/CustomApps/marketplace"
# The Dotfiles theme lives in the repo (common/spicetify, which stow skips) and spicetify reads it
# through this link. Its color.ini links through the active colorscheme, so the colorscheme changer
# only has to ask spicetify to refresh.
theme_source="$DOTFILES_DIR/common/spicetify/Themes/Dotfiles"
theme_link="$spicetify_config/Themes/Dotfiles"
# Spotify writes this on its first start; spicetify cannot apply without it.
spotify_prefs="${XDG_CONFIG_HOME:-$HOME/.config}/spotify/prefs"
export PATH="$spicetify_dir:$PATH"

# Downloads the latest spicetify release into ~/.spicetify. Not the official installer: it asks
# questions on /dev/tty and appends to the shell rc (our stowed .zshrc already adds ~/.spicetify).
install_spicetify_cli() {
    local releases=https://github.com/spicetify/cli/releases tag target tarball
    case "$(uname -m)" in
        x86_64) target=linux-amd64 ;;
        aarch64) target=linux-arm64 ;;
        *) error "spicetify has no release for $(uname -m)"; return 1 ;;
    esac
    tag="$(curl -fsSL -H 'Accept: application/json' "$releases/latest" | sed -n 's/.*"tag_name":"v\{0,1\}\([^"]*\)".*/\1/p')"
    [[ -n "$tag" ]] || { error "could not find the latest spicetify release"; return 1; }
    mkdir -p "$spicetify_dir"
    tarball="$spicetify_dir/spicetify.tar.gz"
    curl -fsSL -o "$tarball" "$releases/download/v$tag/spicetify-$tag-$target.tar.gz"
    tar xzf "$tarball" -C "$spicetify_dir"
    rm "$tarball"
    chmod +x "$spicetify_dir/spicetify"
}

if [[ ! -d "$spotify_dir" ]]; then
    warn "Spotify is not installed in $spotify_dir; skipping spicetify."
    summary_add skipped "spicetify (Spotify is not installed)"
    exit 0
fi

# theme_linked: whether spicetify's Themes/Dotfiles leads to the repo's theme.
theme_linked() {
    [[ -L "$theme_link" && "$(readlink "$theme_link")" == "$theme_source" ]]
}

# themed: whether spicetify's config already uses the Dotfiles theme with its colours and CSS. Read
# from the file, since every spicetify call logs a version check.
themed() {
    local config="$spicetify_config/config-xpui.ini" key value
    [[ -f "$config" ]] || return 1
    for key in current_theme=Dotfiles color_scheme=base inject_css=1 replace_colors=1; do
        value="$(sed -n "s/^${key%%=*}[[:space:]]*=[[:space:]]*//p" "$config")"
        [[ "$value" == "${key#*=}" ]] || return 1
    done
}

if command -v spicetify >/dev/null && [[ -d "$marketplace_dir" ]] && theme_linked && themed; then
    info "spicetify and its marketplace are already installed."
    summary_add skipped "spicetify (already installed)"
    exit 0
fi

if ! command -v spicetify >/dev/null; then
    info "Installing spicetify..."
    install_spicetify_cli
    summary_add installed spicetify
fi

if [[ ! -f "$spotify_prefs" ]]; then
    warn "Spotify has never been opened, so spicetify cannot apply yet: open Spotify once, then run bootstrap.sh --spicetify again."
    summary_add skipped "spicetify apply (open Spotify once, then run with --spicetify again)"
    exit 0
fi

if ! theme_linked; then
    mkdir -p "$(dirname "$theme_link")"
    ln -sfn "$theme_source" "$theme_link"
fi
if ! themed; then
    info "Theming Spotify with the Dotfiles theme..."
    spicetify config current_theme Dotfiles color_scheme base inject_css 1 replace_colors 1
    summary_add installed "spicetify theme Dotfiles"
fi

# spicetify patches Spotify's files in place. Once they are writable (an earlier run, or a Spotify
# update not yet installed since), sudo is not needed again.
if [[ ! -w "$spotify_dir" || -n "$(find "$spotify_dir/Apps" ! -writable -print -quit)" ]]; then
    sudo chmod a+wr "$spotify_dir"
    sudo chmod -R a+wr "$spotify_dir/Apps"
fi

if [[ -d "$marketplace_dir" ]]; then
    # Applied before: only the theme was missing.
    spicetify apply
    exit 0
fi

spicetify backup apply

info "Installing the spicetify marketplace..."
# Downloaded whole first, so a dropped connection runs none of it.
marketplace_installer="$(mktemp)"
trap 'rm -f "$marketplace_installer"' EXIT
curl -fsSL -o "$marketplace_installer" https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh
sh "$marketplace_installer"
summary_add installed "spicetify marketplace"
