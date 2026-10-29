#!/usr/bin/env bash
# Runs bootstrap.sh against a throwaway HOME. Needs no root and never touches the real home.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BOOTSTRAP="$REPO/bootstrap.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    return 1
}

# Runs bootstrap in a fresh temp HOME from a cwd outside the repo.
# Sets OUT and STATUS; TEST_HOME stays for assertions.
run_bootstrap() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    STATUS=0
    OUT="$(cd "$TEST_HOME" && env HOME="$TEST_HOME" PATH="${EXTRA_PATH:+$EXTRA_PATH:}$PATH" bash "$BOOTSTRAP" "$@" 2>&1)" || STATUS=$?
}

test_help_lists_the_flags() {
    run_bootstrap --help
    [[ $STATUS -eq 0 ]] || fail "--help exited $STATUS"
    for flag in --host --minimal --stow-only --no-system --spicetify --help; do
        grep -q -- "$flag" <<<"$OUT" || fail "--help does not mention $flag"
    done
}

test_unknown_flag_exits_non_zero() {
    run_bootstrap --no-such-flag
    [[ $STATUS -ne 0 ]] || fail "unknown flag exited 0"
    grep -q -- "--no-such-flag" <<<"$OUT" || fail "error does not name the flag"
}

test_refuses_to_run_as_root() {
    EXTRA_PATH="$SCRATCH/fake-root"
    mkdir -p "$EXTRA_PATH"
    printf '#!/bin/sh\n[ "$1" = -u ] && echo 0 || /usr/bin/id "$@"\n' >"$EXTRA_PATH/id"
    chmod +x "$EXTRA_PATH/id"
    run_bootstrap --stow-only --host none
    [[ $STATUS -ne 0 ]] || fail "ran as root and exited 0"
    grep -qi "root" <<<"$OUT" || fail "error does not mention root"
    [[ -z "$(ls -A "$TEST_HOME")" ]] || fail "touched HOME before refusing: $(ls -A "$TEST_HOME")"
}

test_stow_only_links_common_from_outside_the_repo() {
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "--stow-only exited $STATUS"
    [[ -L "$TEST_HOME/.zshrc" ]] || fail ".zshrc is not a symlink"
    [[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$REPO/common/.zshrc" ]] || fail ".zshrc does not point into the repo"
    [[ ! -e "$TEST_HOME/bootstrap" ]] || fail "stowed the bootstrap dir"
}

test_stow_only_links_the_host_dir_when_it_exists() {
    run_bootstrap --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "--stow-only --host omelas exited $STATUS"
    [[ "$(readlink -f "$TEST_HOME/.config/hyprdynamicmonitors/config.toml")" == "$REPO/host-omelas/.config/hyprdynamicmonitors/config.toml" ]] \
        || fail "host-omelas was not stowed"
}

test_each_run_writes_a_log_and_prints_a_summary() {
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -qi "summary" <<<"$OUT" || fail "no summary printed"
    local logs=("$TEST_HOME"/.local/state/dotfiles/bootstrap-*.log)
    [[ -f "${logs[0]}" ]] || fail "no log under ~/.local/state/dotfiles"
    grep -qi "summary" "${logs[0]}" || fail "log does not hold the run's output"
}

test_a_failing_step_exits_non_zero_and_still_prints_the_summary() {
    EXTRA_PATH="$SCRATCH/failing-stow"
    mkdir -p "$EXTRA_PATH"
    printf '#!/bin/sh\nexit 1\n' >"$EXTRA_PATH/stow"
    chmod +x "$EXTRA_PATH/stow"
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -ne 0 ]] || fail "a failing stow exited 0"
    grep -q "Failed:" <<<"$OUT" || fail "summary does not list the failure"
    grep -q "step stow" <<<"$OUT" || fail "summary does not name the failed step"
}

# Runs bootstrap again in the current TEST_HOME. Sets OUT and STATUS.
rerun_bootstrap() {
    STATUS=0
    OUT="$(cd "$TEST_HOME" && env HOME="$TEST_HOME" bash "$BOOTSTRAP" "$@" 2>&1)" || STATUS=$?
}

test_a_pre_existing_file_is_backed_up_and_replaced_by_the_link() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    echo "mine" >"$TEST_HOME/.zshrc"
    rerun_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$REPO/common/.zshrc" ]] || fail ".zshrc is not linked into the repo"
    local backups=("$TEST_HOME"/.dotfiles-backup/*/.zshrc)
    [[ -f "${backups[0]}" ]] || fail "no .zshrc under ~/.dotfiles-backup/<ts>/"
    [[ "$(cat "${backups[0]}")" == mine ]] || fail "the backup does not hold the old .zshrc"
    grep -A20 "Backed up:" <<<"$OUT" | grep -q ".zshrc" || fail "summary does not list the backed-up .zshrc"
}

test_a_second_run_backs_up_nothing() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    echo "mine" >"$TEST_HOME/.zshrc"
    rerun_bootstrap --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "first run exited $STATUS"
    local before
    before="$(find "$TEST_HOME/.dotfiles-backup" | sort)"
    sleep 1
    rerun_bootstrap --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    ! grep -q "Backed up:" <<<"$OUT" || fail "second run backed something up"
    [[ "$(find "$TEST_HOME/.dotfiles-backup" | sort)" == "$before" ]] || fail "second run changed ~/.dotfiles-backup"
}

test_a_file_in_the_way_of_a_host_link_is_backed_up_keeping_its_path() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    local rel=.config/hyprdynamicmonitors/config.toml
    mkdir -p "$TEST_HOME/$(dirname "$rel")"
    echo "mine" >"$TEST_HOME/$rel"
    rerun_bootstrap --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(readlink -f "$TEST_HOME/$rel")" == "$REPO/host-omelas/$rel" ]] || fail "$rel is not linked into host-omelas"
    local backups=("$TEST_HOME"/.dotfiles-backup/*/"$rel")
    [[ "$(cat "${backups[0]}")" == mine ]] || fail "no backup of $rel at its relative path"
}

test_an_unknown_host_stows_common_only_with_a_note() {
    run_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -qi "no host-no-such-host dir.*common only" <<<"$OUT" || fail "no note about stowing common only"
    [[ ! -e "$TEST_HOME/.config/hyprdynamicmonitors" ]] || fail "stowed a host dir"
}

test_host_sodoma_stows_sodoma() {
    run_bootstrap --stow-only --host sodoma
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "stow: host-sodoma" <<<"$OUT" || fail "summary does not list host-sodoma"
    local f
    f="$(cd "$REPO/host-sodoma" && find . -type f | head -1)"
    [[ "$(readlink -f "$TEST_HOME/$f")" == "$(readlink -f "$REPO/host-sodoma/$f")" ]] || fail "$f is not linked from host-sodoma"
}

# Runs a snippet the way a step does: sourcing lib.sh with the env bootstrap.sh exports.
# Sets OUT, STATUS and SUMMARY (the lines the snippet added to the summary).
run_as_step() {
    local no_system="$1" snippet="$2" summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(env DOTFILES_NO_SYSTEM="$no_system" DOTFILES_SUMMARY_FILE="$summary" \
        bash -c "source '$REPO/common/bootstrap/lib.sh'; $snippet" 2>&1)" || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

test_no_system_makes_system_changes_skip_and_says_so() {
    run_as_step true 'if system_changes_allowed "chsh to zsh"; then echo CHANGED; fi'
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q CHANGED <<<"$OUT" || fail "made a system change under --no-system"
    grep -q "^skipped.*chsh to zsh.*--no-system" <<<"$SUMMARY" || fail "summary does not record the skip: $SUMMARY"
}

test_without_no_system_system_changes_go_ahead() {
    run_as_step false 'if system_changes_allowed "chsh to zsh"; then echo CHANGED; fi'
    grep -q CHANGED <<<"$OUT" || fail "skipped a system change without --no-system"
    [[ -z "$SUMMARY" ]] || fail "recorded a skip without --no-system: $SUMMARY"
}

# A bare repo holding the working tree as it is now, standing in for GitHub.
make_remote() {
    REMOTE="$SCRATCH/remote.git"
    [[ -d "$REMOTE" ]] && return 0
    local src="$SCRATCH/remote-src"
    mkdir -p "$src"
    (cd "$REPO" && git ls-files -co --exclude-standard -z | tar --null --no-recursion -T - -cf - | tar -xf - -C "$src")
    git -C "$src" init -q -b main
    git -C "$src" add -A
    git -C "$src" -c user.name=t -c user.email=t@t commit -qm snapshot
    git clone -q --bare "$src" "$REMOTE"
}

# Pipes bootstrap.sh into bash, the way curl | bash does, from a cwd outside any clone.
pipe_bootstrap() {
    make_remote
    STATUS=0
    OUT="$(cd "$TEST_HOME" && env HOME="$TEST_HOME" DOTFILES_REPO_URL="file://$REMOTE" bash -s -- "$@" <"$BOOTSTRAP" 2>&1)" || STATUS=$?
}

test_piped_into_bash_clones_the_repo_and_runs_from_the_clone() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    pipe_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "piped bootstrap exited $STATUS"
    [[ -f "$TEST_HOME/.dotfiles/bootstrap.sh" ]] || fail "repo was not cloned to ~/.dotfiles"
    [[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$TEST_HOME/.dotfiles/common/.zshrc" ]] \
        || fail ".zshrc is not linked from the clone"
}

test_the_clone_pushes_over_ssh_and_says_to_add_a_key() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    pipe_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "piped bootstrap exited $STATUS"
    [[ "$(git -C "$TEST_HOME/.dotfiles" remote get-url origin)" == "git@github.com:ndrolp/new-dots.git" ]] \
        || fail "origin is $(git -C "$TEST_HOME/.dotfiles" remote get-url origin)"
    grep -qi "ssh key" <<<"$OUT" || fail "no reminder to add an SSH key"
}

test_a_second_run_updates_the_existing_clone_instead_of_recloning() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    pipe_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "first run exited $STATUS"
    touch "$TEST_HOME/.dotfiles/marker-from-first-run"
    local work="$SCRATCH/remote-work"
    rm -rf "$work" && git clone -q "$REMOTE" "$work"
    echo new >"$work/pushed-after-first-run"
    git -C "$work" add -A && git -C "$work" -c user.name=t -c user.email=t@t commit -qm next && git -C "$work" push -q
    pipe_bootstrap --stow-only --host no-such-host
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    [[ -e "$TEST_HOME/.dotfiles/marker-from-first-run" ]] || fail "the clone was replaced"
    [[ -e "$TEST_HOME/.dotfiles/pushed-after-first-run" ]] || fail "the clone was not updated"
    [[ "$(git -C "$TEST_HOME/.dotfiles" remote get-url origin)" == "git@github.com:ndrolp/new-dots.git" ]] \
        || fail "origin changed on the second run"
}

# Fakes for the network installers and the system tools the shell and node steps call.
# Every call is appended to $CALLS so tests can check what ran and how.
make_shims() {
    SHIMS="$SCRATCH/shims"
    [[ -d "$SHIMS" ]] && return 0
    mkdir -p "$SHIMS"
    # curl serves a fake installer for each URL the steps pipe into a shell.
    cat >"$SHIMS/curl" <<'EOF'
#!/usr/bin/env bash
url="${*: -1}"
echo "curl $url" >>"$CALLS"
case "$url" in
    *ohmyzsh*)
        cat <<'INSTALLER'
echo "oh-my-zsh-installer RUNZSH=$RUNZSH CHSH=$CHSH KEEP_ZSHRC=$KEEP_ZSHRC args=$*" >>"$CALLS"
mkdir -p "$HOME/.oh-my-zsh"
touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"
[ -e "$HOME/.zshrc" ] && [ "$KEEP_ZSHRC" = yes ] || echo "# oh-my-zsh template" >"$HOME/.zshrc"
INSTALLER
        ;;
    *nvm-sh/nvm*)
        cat <<'INSTALLER'
echo "nvm-installer NVM_DIR=$NVM_DIR PROFILE=$PROFILE" >>"$CALLS"
[ -d "$NVM_DIR" ] || { echo "NVM_DIR does not exist" >&2; exit 1; }
cat >"$NVM_DIR/nvm.sh" <<'NVM'
nvm() {
    echo "nvm $*" >>"$CALLS"
    case "$1" in
        version) [ -e "$NVM_DIR/lts-installed" ] && echo v22.0.0 || echo N/A ;;
        install) [ "$2" = --lts ] && touch "$NVM_DIR/lts-installed" ;;
    esac
}
NVM
INSTALLER
        ;;
    *) echo "unexpected url $url" >&2; exit 1 ;;
esac
EOF
    # git fakes clones from GitHub and passes anything else to the real git.
    cat >"$SHIMS/git" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == clone && "$*" == *github.com* ]]; then
    echo "git $*" >>"$CALLS"
    mkdir -p "${*: -1}"
    exit 0
fi
exec /usr/bin/git "$@"
EOF
    printf '#!/bin/sh\necho "sudo $*" >>"$CALLS"\nexec "$@"\n' >"$SHIMS/sudo"
    printf '#!/bin/sh\necho "chsh $*" >>"$CALLS"\n' >"$SHIMS/chsh"
    # getent reports the login shell in $FAKE_LOGIN_SHELL.
    printf '#!/bin/sh\necho "$3:x:1000:1000::/home/$3:$FAKE_LOGIN_SHELL"\n' >"$SHIMS/getent"
    chmod +x "$SHIMS"/*
}

# run_step_alone <step> [VAR=value...]: runs steps/<step>.sh on its own in TEST_HOME
# with the shims first in PATH. Sets OUT, STATUS and SUMMARY.
run_step_alone() {
    local step="$1"
    shift
    make_shims
    local summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(cd "$TEST_HOME" && env -u ZSH -u ZSH_CUSTOM -u NVM_DIR HOME="$TEST_HOME" PATH="$SHIMS:$PATH" \
        CALLS="$CALLS" DOTFILES_SUMMARY_FILE="$summary" DOTFILES_NO_SYSTEM=false FAKE_LOGIN_SHELL=/bin/bash \
        "$@" bash "$REPO/common/bootstrap/steps/$step.sh" 2>&1)" || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

fresh_home() {
    TEST_HOME="$(mktemp -d "$SCRATCH/home.XXXX")"
    CALLS="$TEST_HOME.calls"
    : >"$CALLS"
}

test_shell_installs_oh_my_zsh_unattended_and_leaves_no_zshrc_for_stow() {
    fresh_home
    run_step_alone shell
    [[ $STATUS -eq 0 ]] || fail "shell step exited $STATUS"
    [[ -f "$TEST_HOME/.oh-my-zsh/oh-my-zsh.sh" ]] || fail "oh-my-zsh is not installed"
    grep -q "oh-my-zsh-installer RUNZSH=no CHSH=no KEEP_ZSHRC=yes args=.*--unattended" "$CALLS" \
        || fail "installer not run unattended: $(cat "$CALLS")"
    [[ ! -e "$TEST_HOME/.zshrc" ]] || fail "left the installer's .zshrc where stow links its own"
}

test_shell_clones_the_plugins_and_theme_into_the_custom_dir_the_zshrc_uses() {
    fresh_home
    run_step_alone shell
    [[ $STATUS -eq 0 ]] || fail "shell step exited $STATUS"
    local custom="$TEST_HOME/.config/zsh_custom"
    grep -q '^export ZSH_CUSTOM="$HOME/.config/zsh_custom"$' "$REPO/common/.zshrc" || fail ".zshrc uses another ZSH_CUSTOM"
    [[ -d "$custom/plugins/zsh-autosuggestions" ]] || fail "zsh-autosuggestions not in $custom/plugins"
    [[ -d "$custom/plugins/zsh-syntax-highlighting" ]] || fail "zsh-syntax-highlighting not in $custom/plugins"
    [[ -d "$custom/themes/spaceship-prompt" ]] || fail "spaceship-prompt not in $custom/themes"
    [[ "$(readlink "$custom/themes/spaceship.zsh-theme")" == "$custom/themes/spaceship-prompt/spaceship.zsh-theme" ]] \
        || fail "spaceship.zsh-theme does not link into spaceship-prompt"
}

test_shell_changes_the_login_shell_to_zsh() {
    fresh_home
    run_step_alone shell
    [[ $STATUS -eq 0 ]] || fail "shell step exited $STATUS"
    grep -q "^chsh -s .*/zsh $(id -un)$" "$CALLS" || fail "chsh to zsh not run: $(cat "$CALLS")"
    grep -q "^sudo chsh" "$CALLS" || fail "chsh not run through sudo, so it would ask for a password"
}

test_shell_leaves_the_login_shell_alone_when_it_is_already_zsh() {
    fresh_home
    run_step_alone shell FAKE_LOGIN_SHELL=/usr/bin/zsh
    [[ $STATUS -eq 0 ]] || fail "shell step exited $STATUS"
    ! grep -q chsh "$CALLS" || fail "ran chsh again: $(cat "$CALLS")"
    grep -q "^skipped.*zsh" <<<"$SUMMARY" || fail "summary does not record the skip: $SUMMARY"
}

test_shell_under_no_system_does_not_change_the_login_shell() {
    fresh_home
    run_step_alone shell DOTFILES_NO_SYSTEM=true
    [[ $STATUS -eq 0 ]] || fail "shell step exited $STATUS"
    ! grep -q chsh "$CALLS" || fail "ran chsh under --no-system"
    grep -q "^skipped.*--no-system" <<<"$SUMMARY" || fail "summary does not record the skip: $SUMMARY"
}

test_a_second_shell_run_installs_nothing_and_says_so() {
    fresh_home
    run_step_alone shell DOTFILES_NO_SYSTEM=true
    : >"$CALLS"
    run_step_alone shell DOTFILES_NO_SYSTEM=true
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    [[ ! -s "$CALLS" ]] || fail "second run downloaded or cloned again: $(cat "$CALLS")"
    ! grep -q "^installed" <<<"$SUMMARY" || fail "second run reports installs: $SUMMARY"
    for what in oh-my-zsh zsh-autosuggestions zsh-syntax-highlighting "spaceship theme"; do
        grep -q "^skipped	$what" <<<"$SUMMARY" || fail "second run does not report $what as skipped: $SUMMARY"
    done
}

test_node_installs_nvm_in_home_and_an_lts_node_without_editing_shell_files() {
    fresh_home
    run_step_alone node
    [[ $STATUS -eq 0 ]] || fail "node step exited $STATUS"
    [[ -f "$TEST_HOME/.nvm/nvm.sh" ]] || fail "nvm is not in ~/.nvm"
    grep -q "nvm-installer NVM_DIR=$TEST_HOME/.nvm PROFILE=/dev/null" "$CALLS" \
        || fail "installer may edit a shell profile: $(cat "$CALLS")"
    grep -q "^nvm install --lts" "$CALLS" || fail "no LTS node installed: $(cat "$CALLS")"
}

test_a_second_node_run_installs_nothing_and_says_so() {
    fresh_home
    run_step_alone node
    : >"$CALLS"
    run_step_alone node
    [[ $STATUS -eq 0 ]] || fail "second run exited $STATUS"
    ! grep -qE "^curl|^nvm install" "$CALLS" || fail "second run installed again: $(cat "$CALLS")"
    grep -q "^skipped	nvm" <<<"$SUMMARY" || fail "nvm not reported as skipped: $SUMMARY"
    grep -q "^skipped	node LTS" <<<"$SUMMARY" || fail "node LTS not reported as skipped: $SUMMARY"
}

test_node_uses_nvm_dir_when_it_is_set() {
    fresh_home
    run_step_alone node NVM_DIR="$TEST_HOME/.config/nvm"
    [[ $STATUS -eq 0 ]] || fail "node step exited $STATUS"
    [[ -f "$TEST_HOME/.config/nvm/nvm.sh" ]] || fail "nvm not installed into NVM_DIR"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
