#!/usr/bin/env bash
# Installs the hardware package groups that match this machine: hardware-any always, plus
# hardware-intel / hardware-amd for the CPU vendor and each GPU vendor, in one pacman batch.
# An NVIDIA GPU is warned about and skipped (no support for now).
# DOTFILES_CPUINFO reads another file instead of /proc/cpuinfo (for tests).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# cpu_vendor: intel, amd or nothing, from the first vendor_id in cpuinfo.
cpu_vendor() {
    case "$(awk -F': *' '/^vendor_id/ { print $2; exit }' "${DOTFILES_CPUINFO:-/proc/cpuinfo}" 2>/dev/null)" in
        GenuineIntel) echo intel ;;
        AuthenticAMD) echo amd ;;
    esac
}

# gpu_vendors: intel, amd and/or nvidia, one per line, from the PCI vendor id of each
# display controller (class 03xx) that lspci -nn lists.
gpu_vendors() {
    lspci -nn | sed -n 's/.*\[03[0-9a-f][0-9a-f]\]:.*\[\([0-9a-f]\{4\}\):[0-9a-f]\{4\}\].*/\1/p' |
        while read -r id; do
            case "$id" in
                8086) echo intel ;;
                1002) echo amd ;;
                10de) echo nvidia ;;
            esac
        done | sort -u
}

vendors=()
cpu="$(cpu_vendor)"
if [[ -n "$cpu" ]]; then
    info "CPU: $cpu"
    vendors+=("$cpu")
else
    warn "Unknown CPU vendor, no microcode installed."
fi

if command -v lspci >/dev/null 2>&1; then
    mapfile -t gpus < <(gpu_vendors)
    info "GPU: ${gpus[*]:-none found}"
    for gpu in "${gpus[@]}"; do
        if [[ "$gpu" == nvidia ]]; then
            warn "NVIDIA GPU found: its drivers are not installed (no support for now)."
            summary_add warning "NVIDIA GPU: drivers not installed (no support for now)"
        else
            vendors+=("$gpu")
        fi
    done
else
    warn "lspci not found (pciutils), GPU drivers not picked."
fi

groups=(hardware-any)
for vendor in $(printf '%s\n' "${vendors[@]}" | sort -u); do
    groups+=("hardware-$vendor")
done
mapfile -t packages < <(package_list "${groups[@]}")

info "Installing hardware packages (${groups[*]})..."
pacman_install "hardware packages: ${groups[*]}" "${packages[@]}"
