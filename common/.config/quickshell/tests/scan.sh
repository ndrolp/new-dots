#!/usr/bin/env bash
# services/scan.sh, which runs one scan for the Printers panel: scanimage
# (sane-backends 1.4) writes <out>.part and renames it to <out> when done.
# A fake scanimage stands in for the real one; it never touches a scanner.
# Usage: common/.config/quickshell/tests/scan.sh
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$QS_DIR/services/scan.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    return 1
}

# A fake scanimage: writes <out>.part, then does what FAKE_SCAN says:
# "ok" renames it and exits 0, "fail" leaves .part and exits 1, "late"
# renames it but exits 1 (a scan saved, then an error).
FAKE="$SCRATCH/fake-scanimage"
cat >"$FAKE" <<'EOF'
#!/usr/bin/env bash
out="${!#}"
echo "Progress: 50.0%" >&2
echo partial >"$out.part"
case "$FAKE_SCAN" in
    ok) mv "$out.part" "$out"; exit 0 ;;
    fail) echo "scanimage: sane_start: Document feeder out of documents" >&2; exit 1 ;;
    late) mv "$out.part" "$out"; echo "scanimage: sane_cancel: Device busy" >&2; exit 1 ;;
esac
EOF
chmod +x "$FAKE"

# Runs the script for <out> with FAKE_SCAN=<mode>; STATUS is its exit code.
scan() {
    local mode="$1" out="$2"
    STATUS=0
    FAKE_SCAN="$mode" bash "$SCRIPT" "$out" "$FAKE" -p -o "$out" 2>"$SCRATCH/stderr" || STATUS=$?
}

test_a_scan_makes_its_folder_and_saves_the_file() {
    local out="$SCRATCH/ok/Pictures/Scans/scan.pdf"
    scan ok "$out"
    [[ $STATUS -eq 0 ]] || fail "exited $STATUS"
    [[ -f "$out" ]] || fail "no $out"
    [[ ! -e "$out.part" ]] || fail ".part left behind"
    grep -q "Progress: 50.0%" "$SCRATCH/stderr" || fail "scanimage's stderr not passed on"
}

test_a_failed_scan_removes_the_part_file_and_exits_with_scanimages_status() {
    local out="$SCRATCH/fail/scan.pdf"
    scan fail "$out"
    [[ $STATUS -eq 1 ]] || fail "exited $STATUS, not scanimage's 1"
    [[ ! -e "$out.part" ]] || fail ".part left behind"
    [[ ! -e "$out" ]] || fail "a file was saved"
    grep -q "Document feeder out of documents" "$SCRATCH/stderr" || fail "scanimage's error not passed on"
}

# The file is never deleted: a scan that made it is saved, with exit 100
# telling that scanimage complained all the same.
test_a_scan_saved_before_scanimage_failed_is_kept() {
    local out="$SCRATCH/late/scan.pdf"
    scan late "$out"
    [[ $STATUS -eq 100 ]] || fail "exited $STATUS, not 100"
    [[ -f "$out" ]] || fail "the saved file was removed"
    grep -q "Device busy" "$SCRATCH/stderr" || fail "scanimage's error not passed on"
}

test_a_failed_scan_leaves_a_file_already_there_alone() {
    local out="$SCRATCH/kept/scan.pdf"
    mkdir -p "${out%/*}"
    echo earlier >"$out"
    scan fail "$out"
    [[ "$(cat "$out")" == earlier ]] || fail "the file already there was touched"
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
