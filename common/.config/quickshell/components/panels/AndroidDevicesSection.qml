import QtQuick
import "../../config" as Config
import "../../services/AndroidDevices.js" as Android
import "." as Panels

// The device list of the Android devices panel: one row per Android device
// with its name and state (Connected · USB / Wi-Fi, USB + Wi-Fi, Available,
// Not seen) and what it offers: Connect, Disconnect, Forget and Connect
// wirelessly. It only shows what it's handed and asks for actions; the
// Android devices service runs them.
Column {
    id: root

    required property var appearance
    // AndroidDevices.js rows.
    property var rows: []
    // Why the panel can't work at all (adb missing); "" otherwise.
    property string unavailable: ""
    // What the last action did, or why it failed ("" otherwise).
    property string message: ""
    property string problem: ""
    // While an action runs; the buttons wait for it.
    property bool busy: false

    // `action` is one of AndroidDevices.js actions(), for `row`.
    signal actionRequested(string action, var row)

    readonly property var actionLabels: ({
        connect: "Connect",
        disconnect: "Disconnect",
        forget: "Forget",
        connectWirelessly: "Connect wirelessly"
    })

    spacing: 4

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Android devices"
    }

    Panels.ShellText {
        width: parent.width
        visible: root.unavailable !== ""
        leftPadding: 8
        text: root.unavailable
        wrapMode: Text.Wrap
        color: theme.red
        font.pixelSize: root.appearance.textSize - 1
    }

    Panels.ShellText {
        visible: root.unavailable === "" && root.rows.length === 0
        leftPadding: 8
        text: "No Android devices"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    Repeater {
        model: root.unavailable === "" ? root.rows : []

        delegate: Panels.PrinterRow {
            id: device

            required property var modelData
            readonly property var offered: Android.actions(modelData)
            readonly property var look: Android.stateLook(modelData)
            readonly property bool waitingForPrompt: modelData.state === "usb" && !modelData.authorized

            width: root.width
            appearance: root.appearance
            glyph: look.glyph
            glyphColor: theme[look.color]
            title: modelData.name
            subtitle: look.text
            trailingWidth: waitingForPrompt ? prompt.width + 10 : buttons.width + 10

            Panels.ShellText {
                id: prompt

                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, device.width / 2)
                visible: device.waitingForPrompt
                text: "Accept the USB debugging prompt on the phone"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignRight
                color: theme.orange
                font.pixelSize: root.appearance.textSize - 2
            }

            Row {
                id: buttons

                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: device.offered

                    delegate: Panels.PopupButton {
                        required property string modelData

                        width: modelData === "connectWirelessly" ? 136 : 86
                        appearance: root.appearance
                        interactive: !root.busy
                        label: root.actionLabels[modelData]
                        labelColor: root.busy ? theme.textDisabled
                            : modelData === "forget" ? theme.red : theme.text
                        onActivated: {
                            if (!root.busy)
                                root.actionRequested(modelData, device.modelData);
                        }
                    }
                }
            }
        }
    }

    Panels.ShellText {
        width: parent.width
        visible: root.unavailable === "" && (root.problem !== "" || root.message !== "")
        leftPadding: 8
        text: root.problem !== "" ? root.problem : root.message
        wrapMode: Text.Wrap
        color: root.problem !== "" ? theme.red : theme.green
        font.pixelSize: root.appearance.textSize - 1
    }
}
