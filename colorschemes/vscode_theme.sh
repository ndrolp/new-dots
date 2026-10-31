#!/usr/bin/env bash
# vscode_theme.sh <theme>     copies VS Code's settings from stdin to stdout with workbench.colorTheme
#                             set to <theme>; every other byte passes through unchanged.
# vscode_theme.sh --default   the same, with the default colorscheme's VS Code theme (the one named in
#                             its vscode-theme.txt). This is the git clean filter for VS Code's tracked
#                             settings file: whatever theme the working copy holds, the repo stores the
#                             default one (docs/adr/0001-active-colorscheme-is-machine-local.md). With no
#                             theme to set, the settings pass through unchanged.
# vscode_theme.sh --register  registers that clean filter (named in .gitattributes) in the clone this
#                             script is in; git only runs a filter its config names.
set -euo pipefail

COLORSCHEMES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

theme="${1:?usage: vscode_theme.sh <theme> | --default | --register}"
if [[ "$theme" == --register ]]; then
    # git runs the filter from the top of the work tree.
    exec git -C "$COLORSCHEMES/.." config filter.vscode-theme.clean 'colorschemes/vscode_theme.sh --default'
fi
if [[ "$theme" == --default ]]; then
    theme_file="$COLORSCHEMES/$("$COLORSCHEMES/colorscheme_changer.sh" --default)/vscode-theme.txt"
    [[ -f "$theme_file" ]] || exec cat
    theme="$(cat "$theme_file")"
fi

json="${theme//\\/\\\\}"
json="${json//\"/\\\"}"
replacement="$(printf '%s' "$json" | sed 's/[\\&|]/\\&/g')"
exec sed -E "s|(\"workbench\\.colorTheme\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\\1\"$replacement\"|"
