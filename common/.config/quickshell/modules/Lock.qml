import Quickshell
import Quickshell.Io
import QtQuick
import "../components/lock" as LockScreen

// The shell's one lock screen and the IPC call that locks it.
Scope {
    id: root

    required property var wallpapers
    required property var appearance

    LockScreen.Lock {
        id: lockScreen

        wallpapers: root.wallpapers
        appearance: root.appearance
    }

    // hypridle's lock_cmd: every way of locking (idle, sleep, the control
    // center's Lock) goes through `loginctl lock-session` and ends here.
    IpcHandler {
        target: "lock"

        function lock(): void {
            lockScreen.lock();
        }
    }
}
