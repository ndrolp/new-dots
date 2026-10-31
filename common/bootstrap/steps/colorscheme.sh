#!/usr/bin/env bash
# Makes the default colorscheme (colorschemes/default.txt) the active one when no colorscheme is active,
# as on a fresh clone. The active colorscheme is machine-local: the gitignored link colorschemes/active
# (docs/adr/0001-active-colorscheme-is-machine-local.md). An active colorscheme is left alone. The
# gitignored link colorschemes/shown, which Hyprland and Quickshell show, starts from it the same way.
# In a clone, also registers the git filter that keeps VS Code's theme out of git.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

active="$("$DOTFILES_DIR/colorschemes/colorscheme_changer.sh" --active)"
info "Active colorscheme: $active"

# VS Code can't include another file, so applying writes the theme into its tracked settings file. The
# clean filter named in .gitattributes stores the default colorscheme's theme instead; git only runs it
# once it is registered in the clone's config. The command runs from the top of the work tree.
if [[ -e "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" config filter.vscode-theme.clean 'colorschemes/vscode_theme.sh --default'
    info "Registered the VS Code theme filter."
fi
