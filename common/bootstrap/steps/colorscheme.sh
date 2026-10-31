#!/usr/bin/env bash
# Makes the default colorscheme (colorschemes/default.txt) the active one when no colorscheme is active,
# as on a fresh clone. The active colorscheme is machine-local: the gitignored link colorschemes/active
# (docs/adr/0001-active-colorscheme-is-machine-local.md). An active colorscheme is left alone.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

active="$("$DOTFILES_DIR/colorschemes/colorscheme_changer.sh" --active)"
info "Active colorscheme: $active"
