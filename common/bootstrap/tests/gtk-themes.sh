#!/usr/bin/env bash
# Tests for the gtk-themes step. git and curl are PATH shims: git clone gives a fake Fausto repo
# whose installer builds the theme named in $FAKE/builds, and curl gives a .tar.xz holding the
# theme named there, so nothing is downloaded and the real ~/.themes is never touched.
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

test_bootstrap_installs_the_gtk_themes_before_stow() {
    run_bootstrap_with_stub_steps
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^step gtk-themes$" "$CALLS" || fail "gtk-themes did not run"
    [[ "$(grep -n '^step gtk-themes$' "$CALLS" | cut -d: -f1)" -lt "$(grep -n '^step stow$' "$CALLS" | cut -d: -f1)" ]] \
        || fail "gtk-themes ran after stow"
}

# sassc, which the themes are built with, comes in the apps group --minimal leaves out.
test_minimal_skips_the_gtk_themes() {
    run_bootstrap_with_stub_steps --minimal
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "^step gtk-themes$" "$CALLS" || fail "gtk-themes ran with --minimal"
}

# The system's commands minus the faked ones, so the real git or curl is unreachable.
SYS_BIN="$SCRATCH/sysbin"
mkdir -p "$SYS_BIN"
for cmd in /usr/bin/*; do
    case "${cmd##*/}" in git | curl) continue ;; esac
    ln -s "$cmd" "$SYS_BIN/"
done

shim() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" >"$FAKE_BIN/$1"
    chmod +x "$FAKE_BIN/$1"
}

# Fresh fakes per test, with an empty HOME. $FAKE/builds maps a Fausto repo or a release asset to
# "<theme it builds> [installer exit status]"; a source missing from it builds nothing.
setup_fakes() {
    FAKE="$(mktemp -d "$SCRATCH/fake.XXXX")"
    FAKE_BIN="$FAKE/bin"
    CALLS="$FAKE/calls"
    mkdir -p "$FAKE_BIN" "$FAKE/home"
    : >"$CALLS"
    : >"$FAKE/builds"
    export FAKE
    shim git '
echo "git $*" >>"$FAKE/calls"
[[ "$1" == clone ]] || exit 0
dir="${!#}"
repo="$(basename "${@: -2:1}" .git)"
mkdir -p "$dir/themes"
read -r theme status < <(awk -v r="$repo" '"'"'$1 == r { print $2, $3 }'"'"' "$FAKE/builds")
cat >"$dir/themes/install.sh" <<EOF
echo "install.sh $repo \$*" >>"\$FAKE/calls"
[[ -z "$theme" ]] || mkdir -p "\$2/$theme/gtk-4.0"
exit ${status:-0}
EOF'
    shim curl '
echo "curl $*" >>"$FAKE/calls"
url="${!#}" out=
while [[ $# -gt 0 ]]; do [[ "$1" == -o ]] && out="$2"; shift; done
theme="$(awk -v a="${url##*/}" '"'"'$1 == a { print $2 }'"'"' "$FAKE/builds")"
[[ -n "$theme" ]] || exit 22
mkdir -p "$FAKE/release/$theme/gtk-4.0"
tar cJf "$out" -C "$FAKE/release" "$theme"'
}

# write_list <lines>...: the themes file the step reads.
write_list() {
    printf '%s\n' "# a comment" "" "$@" >"$FAKE/gtk-themes.txt"
}

# run_step: runs steps/gtk-themes.sh alone. Sets OUT, STATUS and SUMMARY.
run_step() {
    local summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(cd "$FAKE/home" && env PATH="$FAKE_BIN:$SYS_BIN" HOME="$FAKE/home" DOTFILES_SUMMARY_FILE="$summary" \
        DOTFILES_GTK_THEMES_FILE="$FAKE/gtk-themes.txt" bash "$REPO/common/bootstrap/steps/gtk-themes.sh" 2>&1 </dev/null)" \
        || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

test_builds_a_fausto_theme_into_the_themes_folder() {
    setup_fakes
    echo "Kanagawa-GKT-Theme Kanagawa-Dark" >"$FAKE/builds"
    write_list "Kanagawa-Dark fausto Kanagawa-GKT-Theme -c dark --tweaks macos"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ -d "$FAKE/home/.themes/Kanagawa-Dark/gtk-4.0" ]] || fail "Kanagawa-Dark is not in ~/.themes"
    grep -q "^git clone .*--sparse https://github.com/Fausto-Korpsvart/Kanagawa-GKT-Theme.git" "$CALLS" \
        || fail "did not clone the repo sparsely"
    grep -q "^git -C .* sparse-checkout set themes$" "$CALLS" || fail "fetched more than the themes folder"
    grep -q "^install.sh Kanagawa-GKT-Theme -d $FAKE/home/.themes -c dark --tweaks macos$" "$CALLS" \
        || fail "did not run the installer with the listed options"
    grep -q "^installed	GTK theme Kanagawa-Dark$" <<<"$SUMMARY" || fail "summary does not list it: $SUMMARY"
}

test_unpacks_a_release_theme_into_the_themes_folder() {
    setup_fakes
    echo "Dracula.tar.xz Dracula" >"$FAKE/builds"
    write_list "Dracula release dracula/gtk Dracula.tar.xz"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ -d "$FAKE/home/.themes/Dracula/gtk-4.0" ]] || fail "Dracula is not in ~/.themes"
    grep -q "^curl .*https://github.com/dracula/gtk/releases/latest/download/Dracula.tar.xz$" "$CALLS" \
        || fail "did not download the latest release asset"
    grep -q "^installed	GTK theme Dracula$" <<<"$SUMMARY" || fail "summary does not list it: $SUMMARY"
}

# Catppuccin's installer asks a question after installing and fails without a terminal.
test_a_theme_whose_installer_fails_after_installing_it_counts_as_installed() {
    setup_fakes
    echo "Catppuccin-GTK-Theme Catppuccin-Dark-MB 1" >"$FAKE/builds"
    write_list "Catppuccin-Dark-MB fausto Catppuccin-GTK-Theme -m dark"
    run_step
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^installed	GTK theme Catppuccin-Dark-MB$" <<<"$SUMMARY" || fail "summary does not list it: $SUMMARY"
    ! grep -q "^failed" <<<"$SUMMARY" || fail "reports a failure: $SUMMARY"
}

test_a_theme_that_does_not_install_is_failed_and_the_rest_go_on() {
    setup_fakes
    echo "Dracula.tar.xz Dracula" >"$FAKE/builds"
    write_list "Rosepine-Dark fausto Rose-Pine-GTK-Theme -c dark" "Dracula release dracula/gtk Dracula.tar.xz"
    run_step
    [[ $STATUS -eq 0 ]] || fail "one failed theme failed the whole step (exited $STATUS)"
    grep -q "^failed	GTK theme Rosepine-Dark$" <<<"$SUMMARY" || fail "the failed theme is not listed: $SUMMARY"
    [[ -d "$FAKE/home/.themes/Dracula/gtk-4.0" ]] || fail "the theme after the failed one was not installed"
}

test_a_second_run_installs_nothing_and_says_so() {
    setup_fakes
    printf '%s\n' "Kanagawa-GKT-Theme Kanagawa-Dark" "Dracula.tar.xz Dracula" >"$FAKE/builds"
    write_list "Kanagawa-Dark fausto Kanagawa-GKT-Theme -c dark" "Dracula release dracula/gtk Dracula.tar.xz"
    run_step
    : >"$CALLS"
    run_step
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    [[ ! -s "$CALLS" ]] || fail "second run cloned or downloaded again"
    ! grep -q "^installed" <<<"$SUMMARY" || fail "second run reports installs: $SUMMARY"
    grep -q "^skipped	2 GTK themes (already installed)$" <<<"$SUMMARY" || fail "skip not reported: $SUMMARY"
}

test_every_colorschemes_gtk_theme_is_listed() {
    OUT=""
    CALLS=/dev/null
    local colors theme
    for colors in "$REPO"/colorschemes/*/gtk/colors.sh; do
        theme="$(sed -n 's/.*gtk-theme "\(.*\)".*/\1/p' "$colors")"
        [[ -n "$theme" ]] || fail "no GTK theme in $colors"
        list_lines_has "$theme" || fail "$theme (from ${colors#"$REPO"/}) is not in gtk-themes.txt"
    done
}

list_lines_has() {
    sed 's/#.*//' "$REPO/common/bootstrap/gtk-themes.txt" | awk '{ print $1 }' | grep -qx "$1"
}

for t in $(declare -F | awk '{print $3}' | grep "^test_.*${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
