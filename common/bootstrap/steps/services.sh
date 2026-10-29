#!/usr/bin/env bash
# Enables the units in common/bootstrap/services.txt (system units with sudo, user units as the
# user) and adds the user to the docker group. Skipped whole under --no-system. Units are only
# enabled, not started: they come up on the next boot or login. A unit that fails to enable is
# listed as failed in the summary and the rest go on.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

system_changes_allowed "services and the docker group" || exit 0

services_file="${DOTFILES_SERVICES_FILE:-}"
services_file="${services_file:-$DOTFILES_DIR/common/bootstrap/services.txt}"

# Runs systemctl for <scope>: as root for system units, as the user for user units.
scoped_systemctl() {
    local scope="$1"
    shift
    if [[ "$scope" == user ]]; then
        systemctl --user "$@"
    else
        sudo systemctl "$@"
    fi
}

info "Enabling services from ${services_file#"$DOTFILES_DIR"/}..."
already=0
failed=0
while read -r scope unit package optional _; do
    if [[ "$optional" == optional ]] && ! pacman -Q "$package" >/dev/null 2>&1; then
        info "Skipping $unit: $package is not installed."
        summary_add skipped "service: $unit ($package not installed)"
    elif scoped_systemctl "$scope" is-enabled --quiet "$unit" 2>/dev/null; then
        already=$((already + 1))
    elif scoped_systemctl "$scope" enable "$unit"; then
        summary_add installed "service: $unit ($scope)"
    else
        warn "Could not enable $unit ($scope), going on with the rest."
        summary_add failed "service: $unit ($scope)"
        failed=$((failed + 1))
    fi
done < <(sed -e 's/#.*//' "$services_file" | grep -v '^[[:space:]]*$')
((already == 0)) || summary_add skipped "$already services (already enabled)"
((failed == 0)) || warn "$failed services failed to enable; they are listed in the summary."

user="$(whoami)"
if [[ " $(id -nG "$user") " == *" docker "* ]]; then
    info "$user is already in the docker group."
else
    sudo usermod -aG docker "$user"
    summary_add installed "$user in the docker group (log in again to use it)"
fi
