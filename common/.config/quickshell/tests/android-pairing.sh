#!/usr/bin/env bash
# services/AndroidPairing.qml, the Android devices panel's pairing service,
# in a real headless `qs` on a scratch config. A fake adb (and qrencode)
# stands in for the real one, and a stand-in Android devices service hands
# it mDNS services and rows; no Android device is touched.
# Usage: common/.config/quickshell/tests/android-pairing.sh
set -uo pipefail

QS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
PASSED=0
FAILED=0

fail() {
    echo "  FAIL: $*"
    return 1
}

mkdir -p "$SCRATCH/bin"
# adb pair always succeeds for the Pixel 10a; every call is logged.
cat >"$SCRATCH/bin/adb" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$ADB_LOG"
[[ "$1" == pair ]] && echo "Successfully paired to $2 [guid=adb-61291JEA326957-AbCdEf]"
exit 0
EOF
cat >"$SCRATCH/bin/qrencode" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$SCRATCH/bin/adb" "$SCRATCH/bin/qrencode"

# Runs `scenario` (a function body taking `pairing`, `devices` and
# `check(name, ok, detail)`, ending with `done()`) against the real pairing
# service and a stand-in Android devices service whose connectPaired answers
# `connectOutcome`. Prints qs's output; fails unless every check passed.
run_scenario() {
    local scenario="$1" connect_outcome="$2" cfg="$SCRATCH/cfg-$RANDOM"
    mkdir -p "$cfg/services" "$SCRATCH/run"
    chmod 700 "$SCRATCH/run"
    cp "$QS_DIR/services/AndroidPairing.qml" "$QS_DIR/services/AndroidPairing.js" \
        "$QS_DIR/services/AndroidDevices.js" "$cfg/services/"
    cat >"$cfg/shell.qml" <<QML
import Quickshell
import QtQuick
import "services" as Services

ShellRoot {
    id: shell

    property int failures: 0

    function check(name, ok, detail) {
        console.log((ok ? "PASS " : "FAIL ") + name + (ok ? "" : ": " + detail));
        if (!ok)
            failures++;
    }

    function done() {
        Qt.exit(failures === 0 ? 0 : 1);
    }

    QtObject {
        id: devices

        property var services: []
        property var rows: []
        property bool busy: false
        property int connects: 0

        function rowFor(serial) {
            return rows.find(row => row.serial === serial) || null;
        }
        function refresh() {}
        function connectPaired(serial, address, done) {
            connects++;
            busy = true;
            Qt.callLater(() => {
                busy = false;
                done("$connect_outcome");
            });
            return true;
        }
    }

    Services.AndroidPairing {
        id: pairing

        devices: devices
    }

    function after(ms, action) {
        const timer = Qt.createQmlObject("import QtQuick; Timer {}", shell);
        timer.interval = ms;
        timer.triggered.connect(action);
        timer.start();
    }

    Component.onCompleted: {
        pairing.watching = true;
        $scenario
    }

    Timer { interval: 15000; running: true; onTriggered: { shell.check("finished in time", false, "timed out"); Qt.exit(1); } }
}
QML
    local out status
    out="$(cd "$SCRATCH" && env -u HYPRLAND_INSTANCE_SIGNATURE -u WAYLAND_DISPLAY -u DISPLAY \
        PATH="$SCRATCH/bin:$PATH" ADB_LOG="$SCRATCH/adb.log" \
        QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$SCRATCH/run" \
        timeout 30 qs -p "$cfg/shell.qml" 2>&1)"
    status=$?
    echo "$out" | grep -oE '(PASS|FAIL) .*' | sed 's/^/    /'
    [[ $status -eq 0 ]] || { echo "$out" | grep -iE 'error|warn' | sed 's/^/    | /'; fail "scenario failed"; }
}

# The Android device that scanned the QR code announces its pairing service
# while a connect is running: it is paired once that connect is done.
test_a_qr_code_scanned_while_busy_is_paired_once_adb_is_free() {
    : >"$SCRATCH/adb.log"
    run_scenario '
        devices.busy = true;
        after(300, () => {
            devices.services = [{ name: pairing.qr.name, type: "pairing", address: "192.168.1.50:39999" }];
            after(800, () => {
                shell.check("waits while busy", pairing.message === "", pairing.message);
                devices.busy = false;
                after(1500, () => {
                    shell.check("paired once free", pairing.message === "Paired, connecting…", pairing.message);
                    shell.done();
                });
            });
        });' unreachable || return 1
    grep -q '^pair 192.168.1.50:39999 ' "$SCRATCH/adb.log" || fail "adb pair didn't run: $(cat "$SCRATCH/adb.log")"
}

# Paired, but connecting failed: pairing says so instead of "Paired, connecting…".
test_a_paired_device_that_doesnt_connect_says_why() {
    : >"$SCRATCH/adb.log"
    run_scenario '
        pairing.pairWithCode("192.168.1.44:41233", "123456");
        after(1500, () => {
            shell.check("paired", pairing.message === "Paired, connecting…", pairing.message);
            devices.rows = [{ serial: "61291JEA326957", name: "Pixel 10a", state: "available",
                announced: "192.168.1.44:37045", wifi: [] }];
            after(800, () => {
                shell.check("tried to connect", devices.connects === 1, devices.connects);
                shell.check("says why", pairing.problem
                    === "Paired with Pixel 10a, but couldn'"'"'t connect: it didn'"'"'t answer. Try Connect once Wireless debugging is on",
                    pairing.problem);
                shell.check("no longer connecting", pairing.message === "", pairing.message);
                shell.done();
            });
        });' unreachable
}

# Paired and connected: pairing names the Android device.
test_a_paired_device_that_connects_is_named() {
    : >"$SCRATCH/adb.log"
    run_scenario '
        pairing.pairWithCode("192.168.1.44:41233", "123456");
        after(1500, () => {
            devices.rows = [{ serial: "61291JEA326957", name: "Pixel 10a", state: "wifi",
                announced: "192.168.1.44:37045", wifi: ["adb-61291JEA326957-AbCdEf._adb-tls-connect._tcp"] }];
            after(500, () => {
                shell.check("named", pairing.message === "Paired with Pixel 10a", pairing.message);
                shell.check("no problem", pairing.problem === "", pairing.problem);
                shell.done();
            });
        });' connected
}

command -v qs >/dev/null || { echo "SKIP: qs not installed"; exit 0; }

for test in $(declare -F | awk '{print $3}' | grep '^test_'); do
    echo "$test"
    if "$test"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
done

echo
echo "$PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
