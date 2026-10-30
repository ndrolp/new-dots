#!/usr/bin/env bash
# Installs the GTK themes in common/bootstrap/gtk-themes.txt into ~/.themes, so every colorscheme's
# GTK theme is there for the colorscheme changer. A theme already installed is skipped. A theme
# that fails to install is listed as failed in the summary and the rest go on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

themes_file="${DOTFILES_GTK_THEMES_FILE:-$DOTFILES_DIR/common/bootstrap/gtk-themes.txt}"
themes_dir="$HOME/.themes"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

# A theme counts as installed once its GTK4 files are there: the changer links those.
installed() { [[ -d "$themes_dir/$1/gtk-4.0" ]]; }

# install_fausto <repo> <installer options...>: builds the theme from a Fausto-Korpsvart repo.
# Only the repo's themes folder is fetched (the rest is icon themes, gigabytes of them), and the
# clone is removed once built. The installer's exit status is not trusted: some ask a question
# after installing and fail without a terminal, so whether the theme got installed is checked
# afterwards instead.
install_fausto() {
    local repo="$1" dir="$work_dir/$1"
    shift
    git clone --quiet --depth=1 --filter=blob:none --sparse "https://github.com/Fausto-Korpsvart/$repo.git" "$dir"
    git -C "$dir" sparse-checkout set themes
    (cd "$dir/themes" && bash install.sh -d "$themes_dir" "$@" </dev/null) || true
    rm -rf "$dir"
}

# install_release <owner/repo> <asset>: unpacks a release .tar.xz into ~/.themes.
install_release() {
    local asset="$work_dir/${2##*/}"
    curl -fsSL -o "$asset" "https://github.com/$1/releases/latest/download/$2"
    tar xJf "$asset" -C "$themes_dir"
}

mkdir -p "$themes_dir"
already=0
failed=0
while read -r name source repo options; do
    if installed "$name"; then
        already=$((already + 1))
        continue
    fi
    info "Installing the GTK theme $name..."
    # options is split into the installer's words on purpose.
    # shellcheck disable=SC2086
    case "$source" in
        fausto) install_fausto "$repo" $options || true ;;
        release) install_release "$repo" $options || true ;;
        *) error "unknown source '$source' for $name" ;;
    esac
    if installed "$name"; then
        summary_add installed "GTK theme $name"
    else
        error "the GTK theme $name was not installed"
        summary_add failed "GTK theme $name"
        failed=$((failed + 1))
    fi
done < <(list_lines "$themes_file")
((already == 0)) || summary_add skipped "$already GTK themes (already installed)"
((failed == 0)) || warn "$failed GTK themes failed to install; they are listed in the summary."
