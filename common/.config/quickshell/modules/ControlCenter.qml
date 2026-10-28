import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    required property var clipboardHistory
    required property var screenCapture
    required property var systemMonitor
    required property var keepAwake
    required property var nightLight
    required property var plugins
    // The features its buttons open.
    required property var audioOutputSelector
    required property var clipboardSelector
    required property var powerMenu
    required property var screenCaptureChooser

    available: plugins.controlCenterEnabled

    Panels.ControlCenter {
        appearance: root.appearance
        monitors: root.monitors
        workspaceService: root.workspaceService
        clipboardHistory: root.clipboardHistory
        screenCapture: root.screenCapture
        systemMonitor: root.systemMonitor
        keepAwake: root.keepAwake
        nightLight: root.nightLight
        open: root.open

        onCloseRequested: root.open = false
        // Audio outputs open over the control center, which stays open.
        onAudioSinksRequested: root.audioOutputSelector.open = true
        onClipboardRequested: root.switchTo(root.clipboardSelector)
        onPowerMenuRequested: root.switchTo(root.powerMenu)
        onScreenCaptureRequested: root.switchTo(root.screenCaptureChooser)
    }

    IpcHandler {
        target: "control-center"

        function toggle() {
            root.toggle();
        }
    }
}
