#!/usr/bin/env bash
# Asks for the sudo password once, up front, and keeps sudo's credentials fresh in the
# background, so the rest of the run needs no more prompts. bootstrap.sh stops the keep-alive
# on exit through the PID it leaves in DOTFILES_KEEPALIVE_PID_FILE; it also stops on its own
# once the process that ran this step is gone. DOTFILES_SUDO_KEEPALIVE_SECONDS sets the interval.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

info "Asking for sudo once for the whole run..."
sudo -v

bootstrap_pid="$PPID"
interval="${DOTFILES_SUDO_KEEPALIVE_SECONDS:-50}"
# Detached from the log pipe so it never holds the run's output open.
(
    sleep_pid=""
    trap '[[ -z "$sleep_pid" ]] || kill "$sleep_pid" 2>/dev/null; exit 0' TERM
    while kill -0 "$bootstrap_pid" 2>/dev/null; do
        sudo -n -v 2>/dev/null || true
        sleep "$interval" &
        sleep_pid=$!
        wait "$sleep_pid" || true
    done
) </dev/null >/dev/null 2>&1 &
[[ -z "$DOTFILES_KEEPALIVE_PID_FILE" ]] || echo "$!" >"$DOTFILES_KEEPALIVE_PID_FILE"
disown
