#!/usr/bin/env bash
# Tests for the preflight, packages, paru, aur and hardware steps. pacman, paru, sudo, rustup, git,
# makepkg and lspci are PATH shims that log their calls, so nothing is installed and no root is needed.
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
    case "${cmd##*/}" in pacman | paru | sudo | rustup | git | makepkg | lspci) continue ;; esac
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
    # lspci prints $FAKE/lspci; $FAKE/cpuinfo is what the hardware step reads for /proc/cpuinfo.
    : >"$FAKE/lspci"
    : >"$FAKE/cpuinfo"
    shim lspci 'echo "lspci $*" >>"$FAKE/calls"; cat "$FAKE/lspci"'
}

# fake_hardware <cpu vendor_id> <lspci -nn line>...: the machine the hardware step sees.
fake_hardware() {
    printf 'processor\t: 0\nvendor_id\t: %s\nmodel name\t: Some CPU\n\n' "$1" >"$FAKE/cpuinfo"
    shift
    printf '%s\n' "00:00.0 Host bridge [0600]: Advanced Micro Devices, Inc. [AMD] Root Complex [1022:14d8]" \
        "$@" >"$FAKE/lspci"
}

INTEL_GPU="00:02.0 VGA compatible controller [0300]: Intel Corporation Arc Graphics 130V/140V GPU [8086:64a0] (rev 04)"
AMD_GPU="03:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [1002:744c] (rev c8)"
NVIDIA_GPU="01:00.0 3D controller [0302]: NVIDIA Corporation AD107M [GeForce RTX 4060 Max-Q] [10de:28e0] (rev a1)"
HW_LISTS=("hardware-any=sof-firmware" "hardware-intel=intel-ucode vulkan-intel"
    "hardware-amd=amd-ucode vulkan-radeon" "hardware-nvidia=vulkan-nouveau")

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
        DOTFILES_SUMMARY_FILE="$summary" DOTFILES_PACKAGES_DIR="$LISTS" DOTFILES_CPUINFO="$FAKE/cpuinfo" \
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

test_hardware_installs_the_intel_set_on_an_intel_machine() {
    setup_fakes
    make_lists "${HW_LISTS[@]}"
    fake_hardware GenuineIntel "$INTEL_GPU"
    run_steps false hardware
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(grep -c '^pacman -S ' "$CALLS")" -eq 1 ]] || fail "not one batch"
    grep -q "^pacman -S --needed --noconfirm sof-firmware intel-ucode vulkan-intel$" "$CALLS" \
        || fail "batch is not hardware-any + hardware-intel"
}

test_hardware_installs_the_amd_set_on_an_amd_machine() {
    setup_fakes
    make_lists "${HW_LISTS[@]}"
    fake_hardware AuthenticAMD "$AMD_GPU"
    run_steps false hardware
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    grep -q "^pacman -S --needed --noconfirm sof-firmware amd-ucode vulkan-radeon$" "$CALLS" \
        || fail "batch is not hardware-any + hardware-amd"
}

test_hardware_installs_both_sets_for_an_intel_cpu_with_an_amd_gpu() {
    setup_fakes
    make_lists "${HW_LISTS[@]}"
    fake_hardware GenuineIntel "$INTEL_GPU" "$AMD_GPU"
    run_steps false hardware
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ "$(grep -c '^pacman -S ' "$CALLS")" -eq 1 ]] || fail "not one batch"
    local batch
    batch="$(grep '^pacman -S ' "$CALLS")"
    for pkg in sof-firmware intel-ucode vulkan-intel amd-ucode vulkan-radeon; do
        [[ " $batch " == *" $pkg "* ]] || fail "$pkg not in the batch: $batch"
    done
}

test_hardware_warns_about_an_nvidia_gpu_and_skips_its_drivers() {
    setup_fakes
    make_lists "${HW_LISTS[@]}"
    fake_hardware GenuineIntel "$INTEL_GPU" "$NVIDIA_GPU"
    run_steps false hardware
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    ! grep -q nouveau "$CALLS" || fail "installed NVIDIA drivers"
    grep -q "^pacman -S --needed --noconfirm sof-firmware intel-ucode vulkan-intel$" "$CALLS" \
        || fail "did not install the rest"
    grep -qi "^warning	.*nvidia" <<<"$SUMMARY" || fail "no NVIDIA warning in the summary: $SUMMARY"
}

test_hardware_warning_is_printed_in_the_summary() {
    local summary
    summary="$(mktemp "$SCRATCH/summary.XXXX")"
    printf 'warning\tNVIDIA GPU: drivers not installed\n' >"$summary"
    OUT="$(DOTFILES_SUMMARY_FILE="$summary" bash -c 'source "$1/common/bootstrap/lib.sh"; print_summary' bash "$REPO" 2>&1)"
    CALLS=/dev/null
    grep -q "NVIDIA GPU: drivers not installed" <<<"$OUT" || fail "warning not printed"
}

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$t"
    ( set -e; "$t" )
    if [[ $? -eq 0 ]]; then PASSED=$((PASSED + 1)); else FAILED=$((FAILED + 1)); echo "  FAILED"; fi
done
echo "passed: $PASSED, failed: $FAILED"
[[ $FAILED -eq 0 ]]
