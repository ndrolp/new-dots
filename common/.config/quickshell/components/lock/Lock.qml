import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import "../../services/LockState.js" as LockState
import "." as Lock

// The lock screen: locks every monitor through the session-lock protocol and
// unlocks once PAM lets the password through. When it locks, checks and
// unlocks is decided in LockState.js; this only carries it out. What each
// monitor shows is LockScreenBody.qml.
Scope {
    id: root

    // When the session is locked (LockState.unlocked and the functions after
    // it).
    property var lockState: LockState.unlocked
    // The password waiting for PAM to ask for it.
    property string pendingPassword: ""

    // Locks every monitor; does nothing while locked.
    function lock() {
        lockState = LockState.lockAsked(lockState);
    }

    function submit(password) {
        const next = LockState.passwordSubmitted(lockState, password);
        if (next === lockState)
            return;
        lockState = next;
        pendingPassword = password;
        if (!pam.start())
            finish("startFailed");
    }

    function finish(result) {
        pendingPassword = "";
        lockState = LockState.authFinished(lockState, result);
    }

    function resultName(result) {
        switch (result) {
        case PamResult.Success:
            return "success";
        case PamResult.Failed:
            return "failed";
        case PamResult.MaxTries:
            return "maxTries";
        default:
            return "error";
        }
    }

    PamContext {
        id: pam

        onPamMessage: {
            if (responseRequired) {
                respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }
        onCompleted: result => root.finish(root.resultName(result))
        onError: root.finish("startFailed")
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    WlSessionLock {
        // Unlocking only ever follows a password PAM let through: once
        // locked, the session stays locked even if the shell dies.
        locked: root.lockState.locked

        WlSessionLockSurface {
            id: surface

            readonly property var monitor: Hyprland.monitorFor(screen)
            // The password field follows the focused monitor; while Hyprland
            // hasn't said which one it is, every monitor shows it, so there
            // is always one to type into.
            readonly property bool focused: !Hyprland.focusedMonitor || !monitor
                || Hyprland.focusedMonitor.name === monitor.name

            color: "black"

            Lock.LockScreenBody {
                anchors.fill: parent
                now: clock.date
                showsPasswordField: surface.focused
                checking: root.lockState.phase === "checking"
                error: root.lockState.error
                onPasswordSubmitted: password => root.submit(password)
            }
        }
    }
}
