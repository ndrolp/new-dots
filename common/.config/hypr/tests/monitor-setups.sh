#!/usr/bin/env bash
# Tests for monitor setups (docs/adr/0002-hyprland-owns-monitor-setups.md). Matching runs under plain
# Lua and the Hyprland side against a stubbed `hl`, so no Hyprland is needed. HOME is an empty folder,
# so the tests can't reach a real saved file.
# Run: common/.config/hypr/tests/monitor-setups.sh [name filter]
set -uo pipefail

HYPR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

for saved in monitor-setups.json monitor-setups.json.bad; do
    if ! git -C "$HYPR" check-ignore -q "$saved"; then
        echo "FAIL  $saved is not gitignored"
        exit 1
    fi
done

env -u XDG_CONFIG_HOME HOME="$SCRATCH" lua "$HYPR/tests/monitor_setups.lua" "$HYPR" "${1:-}"
