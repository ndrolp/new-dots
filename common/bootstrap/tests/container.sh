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

# The whole bootstrap with the real core, core-aur and hardware lists (--minimal leaves out the
# apps groups), then a second run in the same container. AUR packages that fail to build are
# reported, not fatal, so they are allowed here. Very slow: builds every core-aur package (~40 min).
test_full_minimal_run_passes_and_a_second_run_changes_nothing() {
    STATUS=0
    OUT="$(TEST_BOOTSTRAP_BEFORE='echo mine >~/.zshrc' \
        TEST_BOOTSTRAP_AFTER='echo "=== second run"
                              bash ~/.dotfiles/bootstrap.sh --no-system --minimal --host omelas || exit
                              [ "$(readlink -f ~/.zshrc)" = ~/.dotfiles/common/.zshrc ] && echo ZSHRC-LINKED
                              [ "$(cat ~/.dotfiles-backup/*/.zshrc)" = mine ] && echo ZSHRC-BACKED-UP' \
        "$HARNESS" --minimal --host omelas 2>&1)" || STATUS=$?
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    local first second
    first="$(sed '/^=== second run/,$d' <<<"$OUT")"
    second="$(sed -n '/^=== second run/,$p' <<<"$OUT")"
    for what in "pacman packages: core" "hardware packages: hardware-any" "paru" oh-my-zsh nvm "stow: common" "stow: host-omelas"; do
        sed -n '/^Installed:/,/^[A-Z]/p' <<<"$first" | grep -q -- "- $what" || fail "first run did not install $what"
    done
    grep -q ZSHRC-LINKED <<<"$OUT" || fail "~/.zshrc is not a link into the repo"
    grep -q ZSHRC-BACKED-UP <<<"$OUT" || fail "the old ~/.zshrc is not in ~/.dotfiles-backup/<ts>/"
    ! grep -q "^Installed:" <<<"$second" || fail "second run installed something"
    ! grep -q "^Backed up:" <<<"$second" || fail "second run backed something up"
    local other_failures
    other_failures="$(sed -n '/^Failed:/,/^Log:/{/^  - /p}' <<<"$second" | grep -v "^  - AUR: " || true)"
    [[ -z "$other_failures" ]] || fail "second run failed something besides AUR builds: $other_failures"
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

# curl ... | bash on a fresh machine: no git and no ~/.dotfiles yet. The repo is served from a
# bare snapshot of the working tree (uncommitted files included) through DOTFILES_REPO_URL.
test_piped_bootstrap_installs_git_clones_the_repo_and_stows_in_a_fresh_container() {
    local snap
    snap="$(mktemp -d)"
    (cd "$REPO" && git ls-files -co --exclude-standard -z | tar --null --no-recursion -T - -cf - | tar -xf - -C "$snap")
    git -C "$snap" init -q -b main && git -C "$snap" add -A \
        && git -C "$snap" -c user.name=t -c user.email=t@t commit -qm snapshot
    git clone -q --bare "$snap" "$snap.git"
    STATUS=0
    OUT="$(docker run --rm --label dotfiles.test-bootstrap=1 -v "$snap.git:/remote.git:ro" \
        -v "$REPO/bootstrap.sh:/bootstrap.sh:ro" "${TEST_BOOTSTRAP_IMAGE:-archlinux:latest}" bash -c '
            set -euo pipefail
            pacman -Syu --noconfirm --needed sudo stow >/dev/null
            useradd -m tester
            echo "tester ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/tester
            cp -r /remote.git /srv/remote.git && chown -R tester:tester /srv/remote.git
            command -v git || echo "state: no git before"
            cd /tmp
            runuser -u tester -- env HOME=/home/tester USER=tester LOGNAME=tester \
                DOTFILES_REPO_URL=file:///srv/remote.git bash -s -- --no-system --stow-only </bootstrap.sh
            cd /home/tester
            echo "state: origin $(runuser -u tester -- git -C .dotfiles remote get-url origin)"
            echo "state: zshrc $(readlink -f .zshrc)"' 2>&1)" || STATUS=$?
    rm -rf "$snap" "$snap.git"
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -qx "state: no git before" <<<"$OUT" || fail "git was already installed, the install path was not exercised"
    grep -q "Installing git" <<<"$OUT" || fail "the piped bootstrap did not install git"
    grep -qx "state: origin git@github.com:ndrolp/new-dots.git" <<<"$OUT" || fail "origin is not the SSH URL"
    grep -qx "state: zshrc /home/tester/.dotfiles/common/.zshrc" <<<"$OUT" || fail ".zshrc is not linked from the clone"
}

# No systemd in the container, so the services step can only be checked under --no-system.
test_services_step_changes_nothing_under_no_system() {
    STATUS=0
    OUT="$(docker run --rm --name "dotfiles-test-services-$$" --label dotfiles.test-bootstrap=1 \
        -v "$REPO:/src:ro" "${TEST_BOOTSTRAP_IMAGE:-archlinux:latest}" bash -c '
            useradd -m tester
            cp -r /src/common /tmp/common
            runuser -u tester -- env HOME=/home/tester DOTFILES_DIR=/tmp DOTFILES_NO_SYSTEM=true \
                DOTFILES_SUMMARY_FILE=/tmp/summary bash -c "
                    source /tmp/common/bootstrap/lib.sh
                    run_step services && print_summary"
            id -nG tester' 2>&1)" || STATUS=$?
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q -- "- services and the docker group (--no-system)" <<<"$OUT" || fail "skip not in the summary"
    ! grep -qw docker <<<"$(tail -1 <<<"$OUT")" || fail "tester was added to docker"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_' | grep -- "${1:-}"); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
