#!/usr/bin/env bash
# Tests for scripts/test-bootstrap. Needs Docker; each test starts a fresh archlinux container.
# An argument runs only the tests whose name contains it.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HARNESS="$REPO/scripts/test-bootstrap"
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | tail -40 | sed 's/^/    | /'
    return 1
}

run_harness() {
    STATUS=0
    OUT="$("$HARNESS" "$@" 2>&1)" || STATUS=$?
}

test_stow_only_passes_in_a_fresh_container() {
    run_harness --stow-only
    [[ $STATUS -eq 0 ]] || fail "test-bootstrap --stow-only exited $STATUS"
    grep -q "stow: common" <<<"$OUT" || fail "the bootstrap did not stow common"
}

test_extra_args_reach_the_bootstrap() {
    run_harness --stow-only --host omelas
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "stow: host-omelas" <<<"$OUT" || fail "--host omelas did not reach the bootstrap"
}

test_a_failing_bootstrap_fails_the_harness() {
    run_harness --no-such-flag
    [[ $STATUS -ne 0 ]] || fail "a bad flag exited 0"
    grep -q -- "Unknown option: --no-such-flag" <<<"$OUT" || fail "the bootstrap did not reject the flag"
}

# The real core list from the repo; a short AUR list (fixtures/packages) so it does not build
# every AUR package, with one that cannot exist. Slow: builds paru (several minutes).
test_package_steps_install_core_and_report_a_bogus_aur_package_as_failed() {
    DOTFILES_PACKAGES_DIR=/home/tester/.dotfiles/common/bootstrap/tests/fixtures/packages \
        run_harness --minimal
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "pacman packages: core$" <<<"$OUT" || fail "core repo packages were not installed"
    grep -q "AUR: neofetch" <<<"$OUT" || fail "neofetch was not installed from the AUR"
    grep -A20 "^Failed:" <<<"$OUT" | grep -q "AUR: dotfiles-bogus-package-that-does-not-exist" \
        || fail "the bogus AUR package is not listed as failed"
    grep -q "stow: common" <<<"$OUT" || fail "the run stopped before stow"
}

test_a_pre_existing_zshrc_is_backed_up_and_linked_in_the_container() {
    STATUS=0
    OUT="$(TEST_BOOTSTRAP_BEFORE='echo mine >~/.zshrc' \
        TEST_BOOTSTRAP_AFTER='[ "$(readlink -f ~/.zshrc)" = ~/.dotfiles/common/.zshrc ] && echo ZSHRC-LINKED
                              [ "$(cat ~/.dotfiles-backup/*/.zshrc)" = mine ] && echo ZSHRC-BACKED-UP' \
        "$HARNESS" --stow-only 2>&1)" || STATUS=$?
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q ZSHRC-LINKED <<<"$OUT" || fail "~/.zshrc is not a link into the repo"
    grep -q ZSHRC-BACKED-UP <<<"$OUT" || fail "the old ~/.zshrc is not in ~/.dotfiles-backup/<ts>/"
}

harness_containers() { docker ps -aq --filter label=dotfiles.test-bootstrap=1 | sort; }

test_no_container_is_left_behind_after_a_pass_or_a_failure() {
    local before after
    before="$(harness_containers)"
    run_harness --stow-only
    run_harness --no-such-flag
    after="$(harness_containers)"
    [[ "$after" == "$before" ]] || fail "containers left behind: $(comm -13 <(echo "$before") <(echo "$after"))"
}

test_no_container_is_left_behind_when_interrupted() {
    local before after pid
    before="$(harness_containers)"
    "$HARNESS" --stow-only >/dev/null 2>&1 &
    pid=$!
    for _ in $(seq 50); do [[ "$(harness_containers)" != "$before" ]] && break; sleep 0.2; done
    kill -INT "$pid"
    wait "$pid" || true
    after="$(harness_containers)"
    OUT=""
    [[ "$after" == "$before" ]] || fail "containers left behind: $(comm -13 <(echo "$before") <(echo "$after"))"
}

# Runs the shell, node and stow steps twice for real (network installers included) in a
# fresh container, then prints the resulting state. zsh, git and curl are preinstalled
# here because the packages step is not run. chsh is allowed: it only changes the container.
read -r -d '' SHELL_NODE_SETUP <<'EOF' || true
set -euo pipefail
pacman -Syu --noconfirm --needed sudo stow zsh git curl >/dev/null
useradd -m tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester
mkdir /home/tester/.dotfiles
tar -C /src --exclude=./.git --exclude=./.claude/worktrees -cf - . | tar -C /home/tester/.dotfiles -xf -
chown -R tester:tester /home/tester/.dotfiles
cd /home/tester
exec runuser -u tester -- env HOME=/home/tester USER=tester LOGNAME=tester bash -c '
    run() {
        DOTFILES_SUMMARY_FILE="$(mktemp)" DOTFILES_HOST=none bash -c "
            source ~/.dotfiles/common/bootstrap/lib.sh
            for s in shell node stow; do run_step \$s || exit 1; done
            print_summary"
    }
    echo "=== first run"; run
    echo "=== second run"; run
    echo "=== state"
    [[ -f ~/.oh-my-zsh/oh-my-zsh.sh ]] && echo "state: oh-my-zsh"
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
        [[ -d ~/.config/zsh_custom/plugins/$p/.git ]] && echo "state: plugin $p"
    done
    [[ -f ~/.config/zsh_custom/themes/spaceship.zsh-theme ]] && echo "state: spaceship theme"
    echo "state: login shell $(getent passwd tester | cut -d: -f7)"
    echo "state: zshrc $(readlink -f ~/.zshrc)"
    echo "state: node $(bash -c "source ~/.nvm/nvm.sh && node --version")"
    echo "state: zsh loads $(zsh -ic "echo \$ZSH_THEME \$NVM_DIR" 2>/dev/null | tail -1)"
'
EOF

test_shell_and_node_steps_install_for_real_and_skip_on_a_second_run() {
    STATUS=0
    OUT="$(docker run --rm --label dotfiles.test-bootstrap=1 -v "$REPO:/src:ro" \
        "${TEST_BOOTSTRAP_IMAGE:-archlinux:latest}" bash -c "$SHELL_NODE_SETUP" 2>&1)" || STATUS=$?
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    local state second
    state="$(sed -n '/^=== state/,$p' <<<"$OUT")"
    second="$(sed -n '/^=== second run/,/^=== state/p' <<<"$OUT")"
    for want in "oh-my-zsh" "plugin zsh-autosuggestions" "plugin zsh-syntax-highlighting" "spaceship theme" \
        "zshrc /home/tester/.dotfiles/common/.zshrc" "zsh loads spaceship /home/tester/.nvm"; do
        grep -qx "state: $want" <<<"$state" || fail "missing after the run: $want"
    done
    grep -qE "^state: login shell /.*/zsh$" <<<"$state" || fail "login shell is not zsh"
    grep -qE "^state: node v[0-9]+\." <<<"$state" || fail "no node installed"
    local reinstalled
    reinstalled="$(sed -n '/^Installed:/,/^Skipped:/p' <<<"$second" | grep '^  - ' | grep -v 'stow:' || true)"
    [[ -z "$reinstalled" ]] || fail "second run installed again: $reinstalled"
    for what in oh-my-zsh zsh-autosuggestions zsh-syntax-highlighting "spaceship theme" "chsh" nvm "node LTS"; do
        grep -q -- "- $what" <<<"$second" || fail "second run does not report $what as skipped"
    done
}

for t in $(declare -F | awk '{print $3}' | grep '^test_' | grep -- "${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
