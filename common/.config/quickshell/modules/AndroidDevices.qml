import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

// The Android devices panel (SUPER+SHIFT+A, `android-devices toggle`): the
// Android devices and known devices, connecting and disconnecting them over
// the network and pairing new ones. The service only reads adb while the
// panel is open.
Feature {
    id: root

    required property var appearance
    required property var androidDevices
    required property var plugins

    available: plugins.androidDevicesEnabled

    Binding {
        target: root.androidDevices
        property: "watching"
        value: root.open
    }

    Panels.AndroidDevicesPanel {
        appearance: root.appearance
        androidDevices: root.androidDevices
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "android-devices"

        function toggle() {
            root.toggle();
        }
    }
}
