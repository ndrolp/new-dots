#!/usr/bin/env bash
# Tests for the vscode-themes step. code is a PATH shim: --list-extensions prints $FAKE/installed and
# --install-extension adds an extension there when $FAKE/available has it, so the real VS Code is
# never touched.
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

test_bootstrap_installs_the_vscode_themes_before_stow() {
    run_bootstrap_with_stub_steps
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step vscode-themes$" "$CALLS" || fail "vscode-themes did not run"
    [[ "$(grep -n '^step vscode-themes$' "$CALLS" | cut -d: -f1)" -lt "$(grep -n '^step stow$' "$CALLS" | cut -d: -f1)" ]] \
        || fail "vscode-themes ran after stow"
}

test_minimal_skips_the_vscode_themes() {
    run_bootstrap_with_stub_steps --minimal
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "^step vscode-themes$" "$CALLS" || fail "vscode-themes ran with --minimal"
}

# The system's commands minus code, so the real one is unreachable.
SYS_BIN="$SCRATCH/sysbin"
mkdir -p "$SYS_BIN"
for cmd in /usr/bin/*; do
    [[ "${cmd##*/}" == code ]] && continue
    ln -s "$cmd" "$SYS_BIN/"
done

# Fresh fakes per test, with an empty HOME and no extension installed or available.
setup_fakes() {
    FAKE="$(mktemp -d "$SCRATCH/fake.XXXX")"
    FAKE_BIN="$FAKE/bin"
    CALLS="$FAKE/calls"
    mkdir -p "$FAKE_BIN" "$FAKE/home"
    : >"$CALLS"
    : >"$FAKE/installed"
    : >"$FAKE/available"
    export FAKE
    cat >"$FAKE_BIN/code" <<'EOF'
#!/usr/bin/env bash
echo "code $*" >>"$FAKE/calls"
case "$1" in
    --list-extensions) cat "$FAKE/installed" ;;
    --install-extension)
        grep -qix "$2" "$FAKE/available" || exit 1
        echo "$2" >>"$FAKE/installed"
        ;;
esac
EOF
    chmod +x "$FAKE_BIN/code"
}

# write_list <lines>...: the themes file the step reads.
write_list() {
    printf '%s\n' "# a comment" "" "$@" >"$FAKE/vscode-themes.txt"
}

# run_step: runs steps/vscode-themes.sh alone. Sets OUT, STATUS and SUMMARY.
run_step() {
    local summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(cd "$FAKE/home" && env PATH="$FAKE_BIN:$SYS_BIN" HOME="$FAKE/home" DOTFILES_SUMMARY_FILE="$summary" \
        DOTFILES_VSCODE_THEMES_FILE="$FAKE/vscode-themes.txt" bash "$REPO/common/bootstrap/steps/vscode-themes.sh" 2>&1 </dev/null)" \
        || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

test_installs_a_listed_extension() {
    setup_fakes
    echo "arcticicestudio.nord-visual-studio-code" >"$FAKE/available"
    write_list "arcticicestudio.nord-visual-studio-code  Nord"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^code --install-extension arcticicestudio.nord-visual-studio-code" "$CALLS" || fail "did not install it"
    grep -q "^installed	VS Code theme Nord$" <<<"$SUMMARY" || fail "summary does not list it: $SUMMARY"
}

# code --list-extensions does not keep the marketplace's capitals.
test_an_installed_extension_is_skipped_whatever_its_case() {
    setup_fakes
    echo "devhippo.midnight-crimson" >"$FAKE/installed"
    write_list "DevHippo.midnight-crimson  Midnight Crimson"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "^code --install-extension" "$CALLS" || fail "installed it again"
    grep -q "^skipped	1 VS Code themes (already installed)$" <<<"$SUMMARY" || fail "skip not reported: $SUMMARY"
}

test_an_extension_that_does_not_install_is_failed_and_the_rest_go_on() {
    setup_fakes
    echo "jdinhlife.gruvbox" >"$FAKE/available"
    write_list "nobody.missing  Missing" "jdinhlife.gruvbox  Gruvbox Dark Medium"
    run_step
    [[ $STATUS -eq 0 ]] || fail "one failed extension failed the whole step (exited $STATUS)"
    grep -q "^failed	VS Code theme Missing$" <<<"$SUMMARY" || fail "the failed extension is not listed: $SUMMARY"
    grep -qx "jdinhlife.gruvbox" "$FAKE/installed" || fail "the extension after the failed one was not installed"
}

test_without_vscode_the_step_skips() {
    setup_fakes
    rm "$FAKE_BIN/code"
    write_list "jdinhlife.gruvbox  Gruvbox Dark Medium"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^skipped	VS Code themes (VS Code is not installed)$" <<<"$SUMMARY" || fail "skip not reported: $SUMMARY"
}

test_every_colorscheme_names_a_vscode_theme_that_is_listed() {
    OUT=""
    CALLS=/dev/null
    local scheme theme
    for scheme in "$REPO"/colorschemes/*/; do
        [[ -f "$scheme/vscode-theme.txt" ]] || fail "$(basename "$scheme") names no VS Code theme"
        theme="$(cat "$scheme/vscode-theme.txt")"
        sed 's/#.*//' "$REPO/common/bootstrap/vscode-themes.txt" | awk 'NF { $1 = ""; sub(/^ +/, ""); print }' \
            | grep -qxF "$theme" || fail "$theme (from $(basename "$scheme")) is not in vscode-themes.txt"
    done
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
