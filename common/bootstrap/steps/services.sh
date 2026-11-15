#!/usr/bin/env bash
# Enables the units in common/bootstrap/services.txt (system units with sudo, user units as the
# user) and adds the user to the docker group. Skipped whole under --no-system. Units are only
# enabled, so they come up on the next boot or login, unless marked now, which also starts them,
# even when already enabled but stopped. A unit that fails to enable or start is listed as failed
# in the summary and the rest go on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

system_changes_allowed "services and the docker group" || exit 0

services_file="${DOTFILES_SERVICES_FILE:-$DOTFILES_DIR/common/bootstrap/services.txt}"

# Runs systemctl for <scope>: as root for system units, as the user for user units.
# is-enabled and is-active only read, so they need no sudo.
scoped_systemctl() {
    local scope="$1"
    shift
    if [[ "$scope" == user ]]; then
        systemctl --user "$@"
    elif [[ "$1" == is-enabled || "$1" == is-active ]]; then
        systemctl "$@"
    else
        sudo systemctl "$@"
    fi
}

info "Enabling services from ${services_file#"$DOTFILES_DIR"/}..."
already=0
failed=0
while read -r scope unit package flags; do
    enable=(enable)
    [[ " $flags " == *" now "* ]] && enable+=(--now)
    if [[ " $flags " == *" optional "* ]] && ! pacman -Q "$package" >/dev/null 2>&1; then
        info "Skipping $unit: $package is not installed."
        summary_add skipped "service: $unit ($package not installed)"
    elif scoped_systemctl "$scope" is-enabled --quiet "$unit" 2>/dev/null; then
        # A now unit enabled earlier without --now (or stopped since) is started all the same.
        if [[ " $flags " == *" now "* ]] && ! scoped_systemctl "$scope" is-active --quiet "$unit" 2>/dev/null; then
            if scoped_systemctl "$scope" start "$unit"; then
                summary_add installed "service: $unit ($scope, started)"
            else
                warn "Could not start $unit ($scope), going on with the rest."
                summary_add failed "service: $unit ($scope, start)"
                failed=$((failed + 1))
            fi
        else
            already=$((already + 1))
        fi
    elif scoped_systemctl "$scope" "${enable[@]}" "$unit"; then
        summary_add installed "service: $unit ($scope)"
    else
        warn "Could not enable $unit ($scope), going on with the rest."
        summary_add failed "service: $unit ($scope)"
        failed=$((failed + 1))
    fi
done < <(list_lines "$services_file")
((already == 0)) || summary_add skipped "$already services (already enabled)"
((failed == 0)) || warn "$failed services failed to enable; they are listed in the summary."

user="$(whoami)"
if [[ " $(id -nG "$user") " == *" docker "* ]]; then
    info "$user is already in the docker group."
else
    sudo usermod -aG docker "$user"
    summary_add installed "$user in the docker group (log in again to use it)"
fi
