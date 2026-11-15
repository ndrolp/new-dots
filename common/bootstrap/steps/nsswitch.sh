#!/usr/bin/env bash
# Lets the machine resolve .local names over mDNS (avahi + nss-mdns), which printers and scanners
# on the network are found by: adds "mdns_minimal [NOTFOUND=return]" to the hosts line of
# /etc/nsswitch.conf, before resolve (or dns when there is no resolve). A hosts line that already
# names an mdns module is left as it is, so a second run changes nothing. Skipped under --no-system.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

system_changes_allowed "mdns in nsswitch.conf" || exit 0

nsswitch_file="${DOTFILES_NSSWITCH_FILE:-/etc/nsswitch.conf}"

# Prints the file with mdns_minimal added to its hosts line. Exits 2 when the hosts line has
# neither resolve nor dns to put it before.
with_mdns() {
    awk '
        /^hosts:/ && !/(^|[[:space:]])mdns/ {
            at = 0
            for (i = 2; i <= NF; i++) if ($i == "resolve") { at = i; break }
            if (!at) for (i = 2; i <= NF; i++) if ($i == "dns") { at = i; break }
            if (!at) { missing = 1; print; next }
            line = $1
            for (i = 2; i <= NF; i++) {
                if (i == at) line = line " mdns_minimal [NOTFOUND=return]"
                line = line " " $i
            }
            print line
            next
        }
        { print }
        END { if (missing) exit 2 }
    ' "$1"
}

new="$(mktemp)"
trap 'rm -f "$new"' EXIT
status=0
with_mdns "$nsswitch_file" >"$new" || status=$?
if ((status == 2)); then
    warn "The hosts line of $nsswitch_file has neither resolve nor dns; add mdns_minimal to it by hand."
    summary_add warning "nsswitch.conf: mdns_minimal not added (no resolve or dns on the hosts line)"
elif ((status != 0)); then
    exit "$status"
elif [[ "$(<"$new")" == "$(<"$nsswitch_file")" ]]; then
    info "$nsswitch_file already resolves mDNS names."
    summary_add skipped "mdns in nsswitch.conf (already there)"
else
    info "Adding mdns_minimal to the hosts line of $nsswitch_file..."
    sudo cp "$new" "$nsswitch_file"
    summary_add installed "mdns in nsswitch.conf"
fi
