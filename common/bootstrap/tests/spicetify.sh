#!/usr/bin/env bash
# Tests for --spicetify and the spicetify step. curl, sudo and spicetify are PATH shims that log
# their calls, so nothing is downloaded, the real Spotify is never touched and no root is needed.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    echo "  calls:"
    sed 's/^/    | /' "$CALLS" 2>/dev/null
    return 1
}

# run_bootstrap_with_stub_steps <args>...: runs bootstrap.sh from a copy of the repo whose steps only log
# their name to $CALLS, so the test sees which steps a flag selects.
run_bootstrap_with_stub_steps() {
    local copy
    copy="$(mktemp -d "$SCRATCH/repo.XXXX")"
    mkdir -p "$copy/common/bootstrap/steps"
    cp "$REPO/bootstrap.sh" "$copy/"
    cp "$REPO/common/bootstrap/lib.sh" "$copy/common/bootstrap/"
    local step
    for step in "$REPO"/common/bootstrap/steps/*.sh; do
        printf 'echo "step %s" >>"$CALLS"\n' "$(basename "$step" .sh)" >"$copy/common/bootstrap/steps/${step##*/}"
    done
    CALLS="$copy.calls"
    : >"$CALLS"
    STATUS=0
    OUT="$(env HOME="$(mktemp -d "$SCRATCH/home.XXXX")" CALLS="$CALLS" bash "$copy/bootstrap.sh" --host none "$@" 2>&1)" \
        || STATUS=$?
}

test_without_the_flag_spicetify_does_not_run() {
    run_bootstrap_with_stub_steps
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step stow$" "$CALLS" || fail "the run did not reach stow"
    ! grep -q "^step spicetify$" "$CALLS" || fail "spicetify ran without --spicetify"
}

test_with_the_flag_spicetify_runs() {
    run_bootstrap_with_stub_steps --spicetify
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step spicetify$" "$CALLS" || fail "spicetify did not run with --spicetify"
}

# The system's commands minus the faked ones, so the real curl, sudo or spicetify is unreachable.
SYS_BIN="$SCRATCH/sysbin"
mkdir -p "$SYS_BIN"
for cmd in /usr/bin/*; do
    case "${cmd##*/}" in curl | sudo | spicetify) continue ;; esac
    ln -s "$cmd" "$SYS_BIN/"
done

shim() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" >"$FAKE_BIN/$1"
    chmod +x "$FAKE_BIN/$1"
}

# Fresh fakes per test. HOME is $FAKE/home, with Spotify installed in $FAKE/spotify and already
# opened once (its prefs file exists). CALLS logs every call.
setup_fakes() {
    FAKE="$(mktemp -d "$SCRATCH/fake.XXXX")"
    FAKE_BIN="$FAKE/bin"
    CALLS="$FAKE/calls"
    SPOTIFY="$FAKE/spotify"
    mkdir -p "$FAKE_BIN" "$FAKE/home/.config/spotify" "$SPOTIFY/Apps"
    touch "$FAKE/home/.config/spotify/prefs"
    : >"$CALLS"
    export FAKE
    shim sudo 'echo "sudo $*" >>"$FAKE/calls"; "$@"'
    # The spicetify release tarball holds this fake spicetify.
    cat >"$FAKE/spicetify" <<'EOF'
#!/usr/bin/env bash
echo "spicetify $*" >>"$FAKE/calls"
EOF
    chmod +x "$FAKE/spicetify"
    # curl serves the latest-release JSON, the release tarball and the marketplace installer.
    shim curl '
url="${!#}"
echo "curl $*" >>"$FAKE/calls"
out=
while [[ $# -gt 0 ]]; do [[ "$1" == -o ]] && out="$2"; shift; done
case "$url" in
    https://github.com/spicetify/cli/releases/latest)
        echo "{\"id\":1,\"tag_name\":\"v2.40.0\",\"update_url\":\"/spicetify/cli/releases/tag/v2.40.0\"}" ;;
    https://github.com/spicetify/cli/releases/download/v2.40.0/spicetify-2.40.0-linux-amd64.tar.gz)
        tar czf "$out" -C "$FAKE" spicetify ;;
    https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh)
        cat <<'"'INSTALLER'"'
echo "marketplace-installer" >>"$FAKE/calls"
mkdir -p "$HOME/.config/spicetify/CustomApps/marketplace"
spicetify apply
INSTALLER
        ;;
    *) echo "unexpected url $url" >&2; exit 1 ;;
esac'
}

# run_spicetify_step [VAR=value...]: runs steps/spicetify.sh alone. Sets OUT, STATUS and SUMMARY.
run_spicetify_step() {
    local summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(cd "$FAKE/home" && env -u XDG_CONFIG_HOME -u SPICETIFY_CONFIG PATH="$FAKE_BIN:$SYS_BIN" HOME="$FAKE/home" \
        SHELL=/usr/bin/zsh DOTFILES_SUMMARY_FILE="$summary" DOTFILES_SPOTIFY_DIR="$SPOTIFY" "$@" \
        bash "$REPO/common/bootstrap/steps/spicetify.sh" 2>&1 </dev/null)" || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

test_installs_spicetify_and_the_marketplace_into_a_writable_spotify_and_applies() {
    setup_fakes
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ -x "$FAKE/home/.spicetify/spicetify" ]] || fail "spicetify is not in ~/.spicetify"
    grep -q "^sudo chmod a+wr $SPOTIFY$" "$CALLS" || fail "Spotify's dir not made writable"
    grep -q "^sudo chmod -R a+wr $SPOTIFY/Apps$" "$CALLS" || fail "Spotify's Apps not made writable"
    grep -q "^spicetify backup apply$" "$CALLS" || fail "no backup before applying"
    grep -q "^marketplace-installer$" "$CALLS" || fail "marketplace not installed"
    [[ "$(grep -n -m1 '^sudo chmod' "$CALLS" | cut -d: -f1)" -lt "$(grep -n '^spicetify backup' "$CALLS" | cut -d: -f1)" ]] \
        || fail "applied before making Spotify writable"
    [[ "$(grep -n '^spicetify backup' "$CALLS" | cut -d: -f1)" -lt "$(grep -n '^marketplace-installer' "$CALLS" | cut -d: -f1)" ]] \
        || fail "installed the marketplace before the backup"
    grep -q "^installed	spicetify$" <<<"$SUMMARY" || fail "summary does not list spicetify: $SUMMARY"
    grep -q "^installed	spicetify marketplace$" <<<"$SUMMARY" || fail "summary does not list the marketplace: $SUMMARY"
}

test_installs_without_prompting_or_editing_shell_files() {
    setup_fakes
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    local left
    left="$(cd "$FAKE/home" && find . -maxdepth 1 -mindepth 1 ! -name .spicetify ! -name .config)"
    [[ -z "$left" ]] || fail "left files in HOME (a shell rc or install.log?): $left"
    grep -q '^export PATH="$PATH:$HOME/.spicetify"$' "$REPO/common/.zshrc" || fail "the stowed .zshrc does not put ~/.spicetify on PATH"
}

test_a_second_run_installs_nothing_and_says_so() {
    setup_fakes
    run_spicetify_step
    : >"$CALLS"
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    [[ ! -s "$CALLS" ]] || fail "second run downloaded, chmodded or applied again"
    ! grep -q "^installed" <<<"$SUMMARY" || fail "second run reports installs: $SUMMARY"
    grep -q "^skipped	spicetify (already installed)$" <<<"$SUMMARY" || fail "skip not reported: $SUMMARY"
}

test_without_spotify_installs_nothing_and_says_why() {
    setup_fakes
    rm -rf "$SPOTIFY"
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ ! -s "$CALLS" ]] || fail "installed spicetify with no Spotify to patch"
    grep -q "^skipped	spicetify (Spotify is not installed)$" <<<"$SUMMARY" || fail "skip not reported: $SUMMARY"
}

# spicetify needs the prefs file Spotify writes on its first start.
test_before_spotify_was_opened_installs_spicetify_but_waits_to_apply() {
    setup_fakes
    rm "$FAKE/home/.config/spotify/prefs"
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ -x "$FAKE/home/.spicetify/spicetify" ]] || fail "spicetify is not installed"
    ! grep -qE "^spicetify|^marketplace-installer|^sudo" "$CALLS" || fail "patched Spotify before it was opened"
    grep -q "^skipped	spicetify apply (open Spotify once, then run with --spicetify again)$" <<<"$SUMMARY" \
        || fail "summary does not say what to do: $SUMMARY"

    touch "$FAKE/home/.config/spotify/prefs"
    : >"$CALLS"
    run_spicetify_step
    [[ $STATUS -eq 0 ]] || fail "the run after opening Spotify exited $STATUS"
    ! grep -q "releases/download" "$CALLS" || fail "downloaded spicetify again"
    grep -q "^spicetify backup apply$" "$CALLS" || fail "did not apply once Spotify had been opened"
    grep -q "^marketplace-installer$" "$CALLS" || fail "did not install the marketplace"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
