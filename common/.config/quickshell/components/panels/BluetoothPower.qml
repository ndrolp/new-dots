import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import "BluetoothPower.js" as BluetoothPower

// Turns Bluetooth on and off for the Bluetooth popup and the Control center.
// Turning on a blocked adapter unblocks it with rfkill first; `error` says
// why the last attempt to turn it on failed.
Scope {
    id: power

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool blocked: !!adapter && adapter.state === BluetoothAdapterState.Blocked
    property string error: ""

    function setEnabled(on) {
        if (!adapter)
            return;

        error = "";
        const step = BluetoothPower.step(on, blocked);
        if (step === "disable") {
            enableTimeout.stop();
            adapter.enabled = false;
            return;
        }

        enableTimeout.restart();
        if (step === "unblock")
            rfkillUnblock.running = true;
        else
            adapter.enabled = true;
    }

    Process {
        id: rfkillUnblock

        command: ["rfkill", "unblock", "bluetooth"]
        onExited: exitCode => {
            if (exitCode !== 0) {
                enableTimeout.stop();
                power.error = BluetoothPower.failure({ unblockFailed: true, blocked: power.blocked });
            } else if (power.adapter) {
                power.adapter.enabled = true;
            }
        }
    }

    Timer {
        id: enableTimeout

        interval: 5000
        onTriggered: {
            if (!power.adapter || power.adapter.enabled)
                return;
            power.error = BluetoothPower.failure({ unblockFailed: false, blocked: power.blocked });
        }
    }

    Connections {
        target: power.adapter

        function onEnabledChanged() {
            if (!power.adapter.enabled)
                return;
            enableTimeout.stop();
            power.error = "";
        }
    }
}
