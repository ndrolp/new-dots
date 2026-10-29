#!/usr/bin/env bash
# Asks for the sudo password once, up front, and keeps sudo's credentials fresh in the
# background until the process that ran this step (bootstrap.sh) exits, so the rest of the
# run needs no more prompts. DOTFILES_SUDO_KEEPALIVE_SECONDS sets the refresh interval.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

info "Asking for sudo once for the whole run..."
sudo -v

bootstrap_pid="$PPID"
interval="${DOTFILES_SUDO_KEEPALIVE_SECONDS:-50}"
# Detached from the log pipe so it never holds the run's output open.
(
    while kill -0 "$bootstrap_pid" 2>/dev/null; do
        sleep "$interval"
        kill -0 "$bootstrap_pid" 2>/dev/null || break
        sudo -n -v 2>/dev/null || true
    done
) </dev/null >/dev/null 2>&1 &
disown
