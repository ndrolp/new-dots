#!/usr/bin/env bash
# Shared by bootstrap.sh and every step file: colors, logging, run_step and the summary.
# Sourcing it is idempotent, so a step file can be run on its own.

[[ -n "${DOTFILES_LIB_LOADED:-}" ]] && return 0
DOTFILES_LIB_LOADED=1

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
DOTFILES_STEPS_DIR="$DOTFILES_DIR/common/bootstrap/steps"
export DOTFILES_DIR

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

header() { printf "\n${GREEN}${BOLD}==> %s${NC}\n" "$*"; }
info() { printf "${CYAN}%s${NC}\n" "$*"; }
warn() { printf "${YELLOW}warning: %s${NC}\n" "$*" >&2; }
error() { printf "${RED}error: %s${NC}\n" "$*" >&2; }

# The summary is a file so steps running in their own process can add to it.
# bootstrap.sh sets it; a step run on its own has no summary to add to.
DOTFILES_SUMMARY_FILE="${DOTFILES_SUMMARY_FILE:-/dev/null}"

# summary_add <step-ok|installed|skipped|backed-up|warning|failed> <what>
# (step-ok is what run_step records for a step that finished; steps use the others.)
summary_add() { printf '%s\t%s\n' "$1" "$2" >>"$DOTFILES_SUMMARY_FILE"; }

# system_changes_allowed <what>: false under --no-system, after recording <what> as skipped.
# Guard every system-wide change (enabling services, chsh) with it:
#   if system_changes_allowed "chsh to zsh"; then chsh -s ...; fi
system_changes_allowed() {
    if [[ "${DOTFILES_NO_SYSTEM:-false}" == true ]]; then
        info "Skipping $1 (--no-system)."
        summary_add skipped "$1 (--no-system)"
        return 1
    fi
}

# The preflight step writes the sudo keep-alive's PID here; bootstrap.sh stops it on exit.
DOTFILES_KEEPALIVE_PID_FILE="${DOTFILES_KEEPALIVE_PID_FILE:-}"

stop_keepalive() {
    [[ -n "$DOTFILES_KEEPALIVE_PID_FILE" && -s "$DOTFILES_KEEPALIVE_PID_FILE" ]] || return 0
    kill "$(cat "$DOTFILES_KEEPALIVE_PID_FILE")" 2>/dev/null || true
    rm -f "$DOTFILES_KEEPALIVE_PID_FILE"
}

# Host whose host-<name> dir is stowed: --host, else the machine's hostname.
dotfiles_host() {
    if [[ -n "${DOTFILES_HOST:-}" ]]; then
        echo "$DOTFILES_HOST"
    else
        hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || hostname
    fi
}

# list_lines <file>: the lines of a list file (package lists, services.txt) without # comments,
# leading or trailing blanks, or empty lines.
list_lines() {
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$' || true
}

# package_list <group>...: the packages in common/packages/<group>.txt, without comments or blank lines.
# DOTFILES_PACKAGES_DIR reads the lists from another dir instead (for tests).
package_list() {
    local group file
    for group in "$@"; do
        file="${DOTFILES_PACKAGES_DIR:-$DOTFILES_DIR/common/packages}/$group.txt"
        [[ -f "$file" ]] || { error "Package list not found: $file"; return 1; }
        list_lines "$file"
    done
}

# package_groups [suffix]: the package groups a run installs, one per line: core<suffix>, and
# apps<suffix> unless --minimal. package_groups -aur gives the AUR groups.
package_groups() {
    echo "core${1:-}"
    [[ "${DOTFILES_MINIMAL:-false}" == true ]] || echo "apps${1:-}"
}

# pacman_install <what> <package>...: installs the packages in one sudo pacman batch and records
# <what> as installed, or, when pacman -T finds every one already there, runs nothing and records
# <what> as skipped (so a second run says it changed nothing). An empty list runs nothing and is
# recorded as skipped too. A failed batch returns non-zero.
pacman_install() {
    local what="$1"
    shift
    if (($# == 0)); then
        info "No $what to install."
        summary_add skipped "$what (nothing to install)"
        return 0
    fi
    if [[ -z "$(pacman -T "$@" || true)" ]]; then
        info "All $what are already installed."
        summary_add skipped "$what (already installed)"
        return 0
    fi
    sudo pacman -S --needed --noconfirm "$@" || return 1
    summary_add installed "$what"
}

# run_step <name>: runs steps/<name>.sh in its own process and records how it went.
run_step() {
    local name="$1"
    header "$name"
    if bash "$DOTFILES_STEPS_DIR/$name.sh"; then
        summary_add step-ok "$name"
    else
        summary_add failed "step $name"
        error "step $name failed"
        return 1
    fi
}

print_summary() {
    local kind label lines
    header "Summary"
    for kind in step-ok installed skipped backed-up warning failed; do
        case "$kind" in
            step-ok) label="Steps done" ;;
            installed) label="Installed" ;;
            skipped) label="Skipped" ;;
            backed-up) label="Backed up" ;;
            warning) label="Warnings" ;;
            failed) label="Failed" ;;
        esac
        lines="$(awk -F'\t' -v k="$kind" '$1 == k { print "  - " $2 }' "$DOTFILES_SUMMARY_FILE")"
        [[ -n "$lines" ]] && printf "%s:\n%s\n" "$label" "$lines"
    done
    [[ -n "${DOTFILES_LOG_FILE:-}" ]] && printf "\nLog: %s\n" "$DOTFILES_LOG_FILE"
    return 0
}
