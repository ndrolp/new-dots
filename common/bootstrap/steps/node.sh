#!/usr/bin/env bash
# Installs nvm when NVM_DIR is set.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if [[ -z "${NVM_DIR:-}" ]]; then
    warn "NVM_DIR is not set, skipping nvm."
    summary_add skipped "nvm (NVM_DIR not set)"
    exit 0
fi

mkdir -p "$NVM_DIR"
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
summary_add installed nvm
