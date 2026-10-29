#!/usr/bin/env bash
# Installs spicetify and its marketplace into the installed Spotify and applies them. Opt-in with --spicetify.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# DOTFILES_SPOTIFY_DIR points at another Spotify install (for tests).
spotify_dir="${DOTFILES_SPOTIFY_DIR:-/opt/spotify}"
spicetify_dir="$HOME/.spicetify"
# Where the marketplace installer puts it.
marketplace_dir="${SPICETIFY_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/spicetify}/CustomApps/marketplace"
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

if command -v spicetify >/dev/null && [[ -d "$marketplace_dir" ]]; then
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

# spicetify patches Spotify's files in place.
sudo chmod a+wr "$spotify_dir"
sudo chmod -R a+wr "$spotify_dir/Apps"
spicetify backup apply

info "Installing the spicetify marketplace..."
curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh | sh
summary_add installed "spicetify marketplace"
