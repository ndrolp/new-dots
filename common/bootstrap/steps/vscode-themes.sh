#!/usr/bin/env bash
# Installs the VS Code theme extensions in common/bootstrap/vscode-themes.txt, so every colorscheme's
# VS Code theme is there for the colorscheme changer. An extension already installed is skipped. One
# that fails to install is listed as failed in the summary and the rest go on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

themes_file="${DOTFILES_VSCODE_THEMES_FILE:-$DOTFILES_DIR/common/bootstrap/vscode-themes.txt}"

if ! command -v code >/dev/null 2>&1; then
    info "VS Code is not installed; skipping its themes."
    summary_add skipped "VS Code themes (VS Code is not installed)"
    exit 0
fi

# Extension ids are case-insensitive, and code --list-extensions lowercases them.
installed_extensions="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
installed() { grep -qxF "${1,,}" <<<"$installed_extensions"; }

already=0
failed=0
while read -r extension label; do
    if installed "$extension"; then
        already=$((already + 1))
        continue
    fi
    info "Installing the VS Code theme $label..."
    if code --install-extension "$extension" </dev/null; then
        summary_add installed "VS Code theme $label"
    else
        error "the VS Code theme $label ($extension) was not installed"
        summary_add failed "VS Code theme $label"
        failed=$((failed + 1))
    fi
done < <(list_lines "$themes_file")
((already == 0)) || summary_add skipped "$already VS Code themes (already installed)"
((failed == 0)) || warn "$failed VS Code themes failed to install; they are listed in the summary."
