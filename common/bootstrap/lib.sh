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

# summary_add <installed|skipped|failed|backed-up> <what>
summary_add() { printf '%s\t%s\n' "$1" "$2" >>"$DOTFILES_SUMMARY_FILE"; }

# Host whose host-<name> dir is stowed: --host, else the machine's hostname.
dotfiles_host() {
    if [[ -n "${DOTFILES_HOST:-}" ]]; then
        echo "$DOTFILES_HOST"
    else
        hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || hostname
    fi
}

# package_list <group>...: the packages in common/packages/<group>.txt, without comments or blank lines.
package_list() {
    local group file
    for group in "$@"; do
        file="$DOTFILES_DIR/common/packages/$group.txt"
        [[ -f "$file" ]] || { error "Package list not found: $file"; return 1; }
        sed -e 's/#.*//' -e 's/[[:space:]]//g' "$file" | grep -v '^$' || true
    done
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
    for kind in step-ok installed skipped backed-up failed; do
        case "$kind" in
            step-ok) label="Steps done" ;;
            installed) label="Installed" ;;
            skipped) label="Skipped" ;;
            backed-up) label="Backed up" ;;
            failed) label="Failed" ;;
        esac
        lines="$(awk -F'\t' -v k="$kind" '$1 == k { print "  - " $2 }' "$DOTFILES_SUMMARY_FILE")"
        [[ -n "$lines" ]] && printf "%s:\n%s\n" "$label" "$lines"
    done
    [[ -n "${DOTFILES_LOG_FILE:-}" ]] && printf "\nLog: %s\n" "$DOTFILES_LOG_FILE"
    return 0
}
