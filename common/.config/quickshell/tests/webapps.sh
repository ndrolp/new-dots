#!/usr/bin/env bash
# The web app files: services/webapps.py creating, listing and deleting web
# apps and converting a local icon. Runs on a scratch XDG_DATA_HOME and
# XDG_CACHE_HOME, offline: it never probes a site or touches ~/.local/share.
# Usage: common/.config/quickshell/tests/webapps.sh
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$QS_DIR/services/webapps.py"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
export XDG_DATA_HOME="$SCRATCH/data" XDG_CACHE_HOME="$SCRATCH/cache"
APPS="$XDG_DATA_HOME/applications"
ICONS="$XDG_DATA_HOME/icons/hicolor/256x256/apps"
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    return 1
}

run() {
    python3 -I "$SCRIPT" "$@"
}

fresh() {
    rm -rf "$XDG_DATA_HOME" "$XDG_CACHE_HOME"
}

test_create_writes_a_desktop_entry_marked_as_a_web_app() {
    fresh
    [[ "$(run create https://web.whatsapp.com/ WhatsApp)" == '{"id": "webapp-whatsapp"}' ]] || fail "id"
    local entry="$APPS/webapp-whatsapp.desktop"
    grep -qx 'Exec=google-chrome-stable "--app=https://web.whatsapp.com/"' "$entry" || fail "Exec"
    grep -qx 'StartupWMClass=chrome-web.whatsapp.com__-Default' "$entry" || fail "StartupWMClass"
    grep -qx 'X-Webapp=true' "$entry" || fail "marker"
    grep -qx 'Icon=applications-internet' "$entry" || fail "a web app without an icon gets the globe"
    desktop-file-validate "$entry" || fail "invalid entry"
}

test_list_shows_only_web_apps() {
    fresh
    mkdir -p "$APPS"
    printf '[Desktop Entry]\nType=Application\nName=Other\nExec=true\n' > "$APPS/other.desktop"
    run create https://github.com/ GitHub >/dev/null
    [[ "$(run list)" == '[{"id": "webapp-github", "name": "GitHub", "url": "https://github.com/", "icon": "applications-internet"}]' ]] \
        || fail "$(run list)"
}

test_the_same_url_twice_is_refused_but_another_url_of_the_site_is_not() {
    fresh
    run create https://docs.google.com/document/d/1 Docs >/dev/null
    run create https://docs.google.com/document/d/1 Docs 2>/dev/null && fail "duplicate created"
    [[ "$(run create https://docs.google.com/document/d/2 Docs)" == '{"id": "webapp-docs-2"}' ]] \
        || fail "second docs web app"
}

test_percent_and_quotes_in_the_url_survive_the_exec_key() {
    fresh
    run create 'https://example.com/a%20b?q="x"' Example >/dev/null
    grep -qx 'Exec=google-chrome-stable "--app=https://example.com/a%%20b?q=\\\\"x\\\\""' \
        "$APPS/webapp-example.desktop" || fail "$(grep Exec "$APPS/webapp-example.desktop")"
    [[ "$(run list)" == *'"url": "https://example.com/a%20b?q=\"x\""'* ]] || fail "url read back"
}

test_a_local_image_becomes_the_icon_and_delete_removes_both() {
    fresh
    magick -size 32x20 xc:red "$SCRATCH/icon.png"
    local icon
    icon="$(run icon "$SCRATCH/icon.png" | python3 -c 'import json,sys; print(json.load(sys.stdin)["icon"])')"
    [[ "$(magick identify -format '%wx%h' "$icon")" == "256x256" ]] || fail "not 256 px"
    run create https://youtube.com/ YouTube "$icon" >/dev/null
    grep -qx "Icon=$ICONS/webapp-youtube.png" "$APPS/webapp-youtube.desktop" || fail "Icon"
    [[ -f "$ICONS/webapp-youtube.png" ]] || fail "icon not copied"
    run delete webapp-youtube >/dev/null || fail "delete"
    [[ ! -e "$APPS/webapp-youtube.desktop" && ! -e "$ICONS/webapp-youtube.png" ]] || fail "left behind"
}

test_delete_refuses_what_is_not_a_web_app() {
    fresh
    mkdir -p "$APPS"
    printf '[Desktop Entry]\nType=Application\nName=Other\nExec=true\n' > "$APPS/webapp-other.desktop"
    run delete webapp-other 2>/dev/null && fail "deleted an unmarked entry"
    run delete ../../evil 2>/dev/null && fail "accepted a path"
    [[ -f "$APPS/webapp-other.desktop" ]] || fail "removed"
}

test_an_unreadable_image_is_refused() {
    fresh
    echo "not an image" > "$SCRATCH/bad.png"
    run icon "$SCRATCH/bad.png" 2>/dev/null && fail "accepted"
    return 0
}

for test in $(declare -F | awk '{print $3}' | grep '^test_'); do
    if "$test"; then
        echo "PASS: $test"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL: $test"
        FAILED=$((FAILED + 1))
    fi
done
echo "Totals: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
