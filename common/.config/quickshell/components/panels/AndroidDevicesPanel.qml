import Quickshell
import QtQuick
import "../../services/AndroidDevices.js" as Android
import "." as Panels

// The Android devices panel's window: a card in the centre of the focused
// monitor (FocusedMonitorPanel.qml) with the device list
// (AndroidDevicesSection.qml) and, under it, *Pair new device*
// (AndroidPairingSection.qml). It shows what the Android devices and
// pairing services read and asks them for every action.
Variants {
    id: root

    required property var appearance
    required property var androidDevices
    required property var androidPairing
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: Panels.FocusedMonitorPanel {
        appearance: root.appearance
        open: root.open
        layerNamespace: "ndro-shell-android-devices"
        contentHeight: sections.implicitHeight
        onCloseRequested: root.closeRequested()

        Connections {
            target: root

            function onOpenChanged() {
                if (root.open)
                    pairing.reset();
            }
        }

        Flickable {
            anchors.fill: parent
            contentHeight: sections.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: sections

                width: parent.width
                spacing: 16

                Panels.AndroidDevicesSection {
                    width: parent.width
                    appearance: root.appearance
                    rows: root.androidDevices.rows
                    unavailable: root.androidDevices.adbProblem
                    message: root.androidDevices.message
                    problem: root.androidDevices.problem
                    busy: root.androidPairing.busy
                    onActionRequested: (action, row) => root.androidDevices[Android.rowActions[action].method](row)
                }

                Panels.AndroidPairingSection {
                    id: pairing

                    width: parent.width
                    visible: root.androidDevices.adbAvailable
                    appearance: root.appearance
                    qrImage: root.androidPairing.qrImage
                    qrProblem: root.androidPairing.qrProblem
                    codeAddress: root.androidPairing.codeAddress
                    paired: root.androidPairing.paired
                    message: root.androidPairing.message
                    problem: root.androidPairing.problem
                    busy: root.androidPairing.busy
                    onPairWithCodeRequested: (address, code) => root.androidPairing.pairWithCode(address, code)
                    onCloseRequested: root.closeRequested()
                }
            }
        }
    }
}
