#!/usr/bin/env bash
# Tests for the preflight, packages, paru, aur and services steps. pacman, paru, sudo, rustup,
# git, makepkg, systemctl, usermod and id are PATH shims that log their calls, so nothing is
# installed or enabled and no root is needed.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

# The system's commands minus the ones the tests fake, so a real pacman, paru or sudo is never
# reachable and a host that has paru looks like one that does not.
SYS_BIN="$SCRATCH/sysbin"
mkdir -p "$SYS_BIN"
for cmd in /usr/bin/*; do
    case "${cmd##*/}" in pacman | paru | sudo | rustup | git | makepkg | systemctl | usermod) continue ;; esac
    ln -s "$cmd" "$SYS_BIN/"
done

fail() {
    echo "  FAIL: $*"
    echo "$OUT" | sed 's/^/    | /'
    echo "  calls:"
    sed 's/^/    | /' "$CALLS" 2>/dev/null
    return 1
}

shim() {
    printf '#!/usr/bin/env bash\n%s\n' "$2" >"$FAKE_BIN/$1"
    chmod +x "$FAKE_BIN/$1"
}

# Fresh fakes per test. CALLS logs every call; PROMPTS gets a line per sudo password prompt.
# sudo credentials last FAKE_SUDO_TTL seconds after the last authentication or use, like
# sudo's timestamp; -n fails instead of prompting when they have expired.
setup_fakes() {
    FAKE="$(mktemp -d "$SCRATCH/fake.XXXX")"
    FAKE_BIN="$FAKE/bin"
    CALLS="$FAKE/calls"
    PROMPTS="$FAKE/prompts"
    mkdir -p "$FAKE_BIN" "$FAKE/installed"
    : >"$CALLS"
    : >"$PROMPTS"
    export FAKE FAKE_SUDO_TTL="${FAKE_SUDO_TTL:-100}"
    shim sudo '
echo "sudo $*" >>"$FAKE/calls"
stamp="$FAKE/sudo-stamp"
fresh() { [[ -f "$stamp" ]] && (( $(date +%s) - $(stat -c %Y "$stamp") < FAKE_SUDO_TTL )); }
if [[ "$1" == -n ]]; then
    shift
    fresh || exit 1
elif ! fresh; then
    echo prompt >>"$FAKE/prompts"
fi
touch "$stamp"
[[ "$1" == -v ]] && exit 0
"$@"'
    # pacman: -Q <pkg> succeeds for anything in $FAKE/installed; FAKE_PACMAN_FAIL makes -S fail;
    # FAKE_UPGRADE_SECONDS makes -Syu take that long.
    shim pacman '
echo "pacman $*" >>"$FAKE/calls"
case "$1" in
    -Q) [[ -e "$FAKE/installed/$2" ]] ;;
    -Syu) sleep "${FAKE_UPGRADE_SECONDS:-0}" ;;
    -S) [[ -z "${FAKE_PACMAN_FAIL:-}" ]] || exit 1 ;;
esac'
    # paru: installing a package named bogus-* fails.
    shim paru '
echo "paru $*" >>"$FAKE/calls"
pkg="${!#}"
[[ "$pkg" != bogus-* ]] || { echo "error: could not find all required packages: $pkg" >&2; exit 1; }
touch "$FAKE/installed/$pkg"'
    shim rustup 'echo "rustup $*" >>"$FAKE/calls"'
    shim git 'echo "git $*" >>"$FAKE/calls"; [[ "$1" == clone ]] && mkdir -p "${!#}"; exit 0'
    # makepkg -si installs paru into the fake bin.
    shim makepkg 'echo "makepkg $*" >>"$FAKE/calls"; cp "$FAKE/paru.real" "$FAKE/bin/paru"'
    # systemctl: is-enabled succeeds for units in $FAKE/enabled (as <system|user>-<unit>);
    # enable adds them there; enabling a unit named bogus-* fails.
    shim systemctl '
echo "systemctl $*" >>"$FAKE/calls"
scope=system
[[ "$1" == --user ]] && { scope=user; shift; }
case "$1" in
    is-enabled) [[ -e "$FAKE/enabled/$scope-${!#}" ]] ;;
    enable) [[ "$2" != bogus-* ]] || exit 1; mkdir -p "$FAKE/enabled"; touch "$FAKE/enabled/$scope-$2" ;;
esac'
    shim usermod 'echo "usermod $*" >>"$FAKE/calls"'
    # id -nG: the user is in the groups listed in FAKE_GROUPS.
    shim id '[[ "$1" == -nG ]] && { echo "${FAKE_GROUPS:-wheel}"; exit 0; }; exec /usr/bin/id "$@"'
}

# A services list; each arg is one line of it.
make_services() {
    SERVICES="$(mktemp "$SCRATCH/services.XXXX")"
    { echo "# a comment"; printf '%s\n' "$@"; } >"$SERVICES"
}

# For tests where paru is not installed yet: moves the paru shim aside for makepkg to install.
without_paru() { mv "$FAKE_BIN/paru" "$FAKE/paru.real"; }

# A package list dir; each arg is <group>=<space-separated packages>.
make_lists() {
    LISTS="$(mktemp -d "$SCRATCH/lists.XXXX")"
    local spec
    for spec in "$@"; do
        { echo "# a comment"; tr ' ' '\n' <<<"${spec#*=}"; } >"$LISTS/${spec%%=*}.txt"
    done
}

# run_steps <minimal> <step>...: runs the steps the way bootstrap.sh does, with the fakes first
# in PATH. Sets OUT, STATUS and SUMMARY.
run_steps() {
    local minimal="$1" summary
    shift
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    STATUS=0
    OUT="$(env PATH="$FAKE_BIN:$SYS_BIN" HOME="$FAKE" DOTFILES_MINIMAL="$minimal" \
        DOTFILES_SUMMARY_FILE="$summary" DOTFILES_PACKAGES_DIR="${LISTS:-}" \
        DOTFILES_SERVICES_FILE="${SERVICES:-}" DOTFILES_NO_SYSTEM="${DOTFILES_NO_SYSTEM:-false}" \
        bash -c 'source "$1/common/bootstrap/lib.sh"; shift; for s in "$@"; do run_step "$s" || exit 1; done' \
        bash "$REPO" "$@" 2>&1)" || STATUS=$?
    SUMMARY="$(cat "$summary")"
}

test_packages_upgrades_then_installs_core_and_apps_in_one_batch() {
    setup_fakes
    make_lists "core=zsh git" "apps=steam"
    run_steps false packages
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^pacman -Syu --noconfirm" "$CALLS" || fail "no system upgrade"
    [[ "$(grep -c '^pacman -S ' "$CALLS")" -eq 1 ]] || fail "not one batch"
    grep -q "^pacman -S --needed --noconfirm zsh git steam$" "$CALLS" || fail "batch is not core + apps"
    [[ "$(grep '^pacman' "$CALLS" | head -1)" == *-Syu* ]] || fail "installed before upgrading"
}

test_minimal_skips_apps() {
    setup_fakes
    make_lists "core=zsh" "apps=steam" "core-aur=wlctl-git" "apps-aur=bogus-app"
    run_steps true packages aur
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q steam "$CALLS" || fail "installed an apps package under --minimal"
    ! grep -q bogus-app "$CALLS" || fail "installed an apps-aur package under --minimal"
    grep -q "^paru .*wlctl-git" "$CALLS" || fail "did not install core-aur"
}

test_a_failing_pacman_batch_fails_the_step() {
    setup_fakes
    make_lists "core=zsh" "apps=steam"
    FAKE_PACMAN_FAIL=1 run_steps false packages
    [[ $STATUS -ne 0 ]] || fail "a failed pacman batch exited 0"
    grep -q "^failed.*packages" <<<"$SUMMARY" || fail "summary does not record it: $SUMMARY"
}

test_aur_packages_install_one_by_one_and_failures_do_not_stop_the_rest() {
    setup_fakes
    make_lists "core-aur=first bogus-package last" "apps-aur=app"
    run_steps false aur
    [[ $STATUS -eq 0 ]] || fail "a failed AUR package failed the step"
    for pkg in first bogus-package last app; do
        grep -q "^paru -S --needed --noconfirm $pkg$" "$CALLS" || fail "$pkg was not installed on its own"
    done
    grep -q "^failed	.*bogus-package" <<<"$SUMMARY" || fail "bogus-package not listed as failed: $SUMMARY"
    grep -q "^installed	.*last" <<<"$SUMMARY" || fail "last not listed as installed: $SUMMARY"
    ! grep -q "^failed	.*first" <<<"$SUMMARY" || fail "first listed as failed"
}

test_aur_skips_packages_that_are_already_installed() {
    setup_fakes
    make_lists "core-aur=there missing" "apps-aur="
    touch "$FAKE/installed/there"
    run_steps false aur
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "^paru .*there" "$CALLS" || fail "reinstalled an installed package"
    grep -q "^paru .*missing" "$CALLS" || fail "did not install the missing one"
}

test_paru_sets_the_rust_toolchain_and_builds_paru_when_missing() {
    setup_fakes
    without_paru
    make_lists
    run_steps false paru
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^rustup default stable$" "$CALLS" || fail "no rustup default stable"
    grep -q "^makepkg -si --noconfirm" "$CALLS" || fail "paru was not built"
    [[ "$(grep -e '^rustup' -e '^makepkg' "$CALLS" | head -1)" == rustup* ]] || fail "built before setting the toolchain"
    [[ -x "$FAKE_BIN/paru" ]] || fail "paru not installed"
}

test_paru_is_not_rebuilt_when_installed() {
    setup_fakes
    make_lists
    run_steps false paru
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "^makepkg" "$CALLS" || fail "rebuilt paru"
}

# The upgrade outlasts sudo's timeout, so without a keep-alive the install batch would prompt again.
test_one_sudo_prompt_up_front_for_the_whole_run() {
    FAKE_SUDO_TTL=2
    setup_fakes
    without_paru
    make_lists "core=zsh" "apps=steam" "core-aur=wlctl-git" "apps-aur=app"
    FAKE_UPGRADE_SECONDS=4 DOTFILES_SUDO_KEEPALIVE_SECONDS=1 run_steps false preflight packages paru aur
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(wc -l <"$PROMPTS")" -eq 1 ]] || fail "$(wc -l <"$PROMPTS") sudo prompts"
    [[ "$(head -1 "$CALLS")" == "sudo -v" ]] || fail "first call is not the sudo prompt: $(head -1 "$CALLS")"
}

test_keep_alive_stops_when_the_bootstrap_ends() {
    setup_fakes
    make_lists
    DOTFILES_SUDO_KEEPALIVE_SECONDS=1 run_steps false preflight
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    sleep 2
    local before after
    before="$(grep -c -- '^sudo -n' "$CALLS" || true)"
    sleep 2
    after="$(grep -c -- '^sudo -n' "$CALLS" || true)"
    [[ "$before" == "$after" ]] || fail "keep-alive still refreshing sudo after the run"
}

test_services_enables_system_units_with_sudo_and_user_units_as_the_user() {
    setup_fakes
    make_services "system sddm sddm" "system docker docker" "user pipewire pipewire"
    run_steps false services
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^sudo systemctl enable sddm$" "$CALLS" || fail "sddm not enabled with sudo"
    grep -q "^sudo systemctl enable docker$" "$CALLS" || fail "docker not enabled with sudo"
    grep -q "^systemctl --user enable pipewire$" "$CALLS" || fail "pipewire not enabled as a user unit"
    ! grep -q "^sudo systemctl --user" "$CALLS" || fail "a user unit was enabled with sudo"
    grep -q "^installed	.*sddm" <<<"$SUMMARY" || fail "sddm not in the summary: $SUMMARY"
}

test_services_enables_an_optional_unit_only_when_its_package_is_installed() {
    setup_fakes
    make_services "system auto-cpufreq auto-cpufreq-git optional" "user openlogi-agent openlogi-bin optional" "system sddm not-installed-but-required"
    touch "$FAKE/installed/openlogi-bin"
    run_steps false services
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q "enable auto-cpufreq" "$CALLS" || fail "enabled auto-cpufreq without its package"
    grep -q "^systemctl --user enable openlogi-agent$" "$CALLS" || fail "openlogi-agent not enabled"
    grep -q "^sudo systemctl enable sddm$" "$CALLS" || fail "a required unit was skipped for its package"
    grep -q "^skipped	.*auto-cpufreq.*auto-cpufreq-git" <<<"$SUMMARY" || fail "skip not in the summary: $SUMMARY"
}

test_services_adds_the_user_to_the_docker_group_once() {
    setup_fakes
    make_services "system docker docker"
    run_steps false services
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^sudo usermod -aG docker $(whoami)$" "$CALLS" || fail "user not added to docker"
    grep -q "^installed	.*docker group" <<<"$SUMMARY" || fail "not in the summary: $SUMMARY"
    : >"$CALLS"
    FAKE_GROUPS="wheel docker" run_steps false services
    ! grep -q "usermod" "$CALLS" || fail "added the user to docker again"
}

test_services_are_skipped_under_no_system() {
    setup_fakes
    make_services "system docker docker" "user pipewire pipewire"
    DOTFILES_NO_SYSTEM=true run_steps false services
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q -e systemctl -e usermod "$CALLS" || fail "changed the system under --no-system"
    grep -q "^skipped	.*(--no-system)" <<<"$SUMMARY" || fail "skip not in the summary: $SUMMARY"
}

test_services_already_enabled_are_not_enabled_again() {
    setup_fakes
    make_services "system sddm sddm" "user pipewire pipewire"
    mkdir -p "$FAKE/enabled"
    touch "$FAKE/enabled/system-sddm" "$FAKE/enabled/user-pipewire"
    run_steps false services
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q " enable " "$CALLS" || fail "enabled an enabled unit again"
    grep -q "^skipped	2 services (already enabled)$" <<<"$SUMMARY" || fail "skip not in the summary: $SUMMARY"
}

test_a_unit_that_fails_to_enable_is_listed_and_the_rest_go_on() {
    setup_fakes
    make_services "system bogus-unit bogus" "system sddm sddm"
    run_steps false services
    grep -q "^sudo systemctl enable sddm$" "$CALLS" || fail "stopped after the failing unit"
    grep -q "^failed	.*bogus-unit" <<<"$SUMMARY" || fail "failure not in the summary: $SUMMARY"
}

# A required unit whose package is not always installed would fail on every --minimal machine.
test_every_required_service_comes_from_a_core_package() {
    local file="$REPO/common/bootstrap/services.txt" core scope unit package optional
    OUT=""
    [[ -f "$file" ]] || fail "no services list at $file"
    core="$(cat "$REPO"/common/packages/core.txt "$REPO"/common/packages/core-aur.txt)"
    while read -r scope unit package optional; do
        [[ "$scope" == system || "$scope" == user ]] || fail "$unit: scope is '$scope'"
        [[ -n "$package" ]] || fail "$unit: no package"
        [[ -z "$optional" || "$optional" == optional ]] || fail "$unit: fourth column is '$optional'"
        [[ "$optional" == optional ]] || grep -qx "$package" <<<"$core" ||
            fail "$unit is required but $package is not in core or core-aur"
    done < <(sed -e 's/#.*//' "$file" | grep -v '^[[:space:]]*$')
    for unit in sddm NetworkManager bluetooth docker cups pipewire pipewire-pulse wireplumber \
        hyprdynamicmonitors auto-cpufreq proton.VPN openlogi-agent; do
        grep -qE "^(system|user) $unit " "$file" || fail "$unit is not in the list"
    done
    for unit in auto-cpufreq proton.VPN openlogi-agent; do
        grep -qE "^(system|user) $unit .* optional" "$file" || fail "$unit is not optional"
    done
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); echo "  FAILED"; fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
