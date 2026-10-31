import Quickshell
import Quickshell.Io
import QtQuick
import "SwitchTo.js" as SwitchTo

// The control center is the bell's popup (components/panels/ControlCenterPopup.qml),
// opened on the focused monitor's bar. This module holds its `control-center`
// IPC call, which opens it expanded (SUPER+C), and the panels its tiles open:
// clipboard, power menu and capture close it and open in its place, unless
// their plugin is off. The audio output tile opens a subpage inside it.
Scope {
    id: root

    // The bar module, which opens the control center on the focused bar.
    required property var bar
    required property var plugins
    // The features its tiles open.
    required property var clipboardSelector
    required property var powerMenu
    required property var screenCaptureChooser

    // Off: the control center is notifications only, with no controls.
    readonly property bool available: plugins.controlCenterEnabled

    // Opens it expanded on the focused bar, or keeps it open there (quick
    // settings' button, through Feature.switchTo).
    function show() {
        bar.openControlCenter("expanded");
    }

    // A tile opens `other` in its place.
    function switchTo(other) {
        SwitchTo.switchTo(() => root.bar.closePopup(), other);
    }

    Connections {
        target: root.bar

        function onClipboardRequested() {
            root.switchTo(root.clipboardSelector);
        }

        function onPowerMenuRequested() {
            root.switchTo(root.powerMenu);
        }

        function onScreenCaptureRequested() {
            root.switchTo(root.screenCaptureChooser);
        }
    }

    IpcHandler {
        target: "control-center"

        function toggle() {
            root.bar.toggleControlCenter("expanded");
        }
    }
}
