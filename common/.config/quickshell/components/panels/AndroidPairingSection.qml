import QtQuick
import "../../config" as Config
import "../../services/AndroidPairing.js" as Pairing
import "." as Panels

// The *Pair new device* section of the Android devices panel. By default it
// shows the QR code the Android device's "Pair device with QR code" scans; the
// service pairs and connects the Android device when it announces the code's name.
// "Use a pairing code" switches to fields for the Android device's IP:port and its
// 6-digit code; the address fills in from mDNS while the Android device's pairing
// dialog is open, and both stay editable.
Column {
    id: root

    required property var appearance
    // The drawn QR code (a file URL, "" until drawn) and why it can't be.
    property string qrImage: ""
    property string qrProblem: ""
    // What an Android device showing its pairing dialog announces ("" otherwise).
    property string codeAddress: ""
    // Once an Android device paired the QR code goes; `message` says which one.
    property bool paired: false
    property string message: ""
    property string problem: ""
    property bool busy: false

    property bool useCode: false
    property string addressText: ""
    property bool addressEdited: false
    property string codeText: ""
    readonly property bool canPair: !busy && Pairing.canPairWithCode(addressText, codeText)

    signal pairWithCodeRequested(string address, string code)
    // Escape in a field, which keeps it from the panel.
    signal closeRequested()

    // Back to the QR code with empty fields, as on every open.
    function reset() {
        useCode = false;
        addressText = codeAddress;
        addressEdited = false;
        codeText = "";
    }

    function pair() {
        if (canPair)
            pairWithCodeRequested(addressText.trim(), codeText.trim());
    }

    onCodeAddressChanged: {
        if (!addressEdited && codeAddress !== "")
            addressText = codeAddress;
    }

    spacing: 8

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Pair new device"
    }

    Panels.ShellText {
        width: parent.width
        visible: !root.paired && !root.useCode
        leftPadding: 8
        text: "On the phone, open Developer options › Wireless debugging › Pair device with QR code, and scan this."
        wrapMode: Text.Wrap
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !root.paired && !root.useCode && root.qrImage !== ""
        width: 196
        height: 196
        radius: root.appearance.radius
        // The code is drawn black on white, which phones read best.
        color: "white"

        Image {
            objectName: "qrCode"

            anchors.centerIn: parent
            width: 180
            height: 180
            fillMode: Image.PreserveAspectFit
            smooth: false
            cache: false
            source: root.qrImage
        }
    }

    Panels.ShellText {
        width: parent.width
        visible: !root.paired && !root.useCode && root.qrProblem !== ""
        leftPadding: 8
        text: root.qrProblem
        wrapMode: Text.Wrap
        color: theme.red
        font.pixelSize: root.appearance.textSize - 1
    }

    Column {
        width: parent.width
        visible: !root.paired && root.useCode
        spacing: 8

        Panels.ShellText {
            width: parent.width
            leftPadding: 8
            text: "On the phone, open Wireless debugging › Pair device with pairing code."
            wrapMode: Text.Wrap
            color: theme.textMuted
            font.pixelSize: root.appearance.textSize - 2
        }

        Row {
            width: parent.width
            spacing: 8

            Panels.PopupTextField {
                id: addressField

                width: parent.width - codeField.width - pairButton.width - 2 * parent.spacing
                appearance: root.appearance
                leftPadding: 10
                placeholderText: "IP address and port"
                text: root.addressText
                onTextEdited: {
                    root.addressText = text;
                    root.addressEdited = true;
                }
                onAccepted: root.pair()
                KeyNavigation.tab: codeField
                Keys.onEscapePressed: root.closeRequested()
            }

            Panels.PopupTextField {
                id: codeField

                width: 110
                appearance: root.appearance
                leftPadding: 10
                placeholderText: "6-digit code"
                inputMethodHints: Qt.ImhDigitsOnly
                maximumLength: 6
                text: root.codeText
                onTextEdited: root.codeText = text
                onAccepted: root.pair()
                KeyNavigation.tab: addressField
                Keys.onEscapePressed: root.closeRequested()
            }

            Panels.PopupButton {
                id: pairButton

                width: 70
                height: addressField.height
                appearance: root.appearance
                interactive: root.canPair
                color: root.canPair ? theme.accent : theme.backgroundSecondary
                label: "Pair"
                labelColor: root.canPair ? theme.background : theme.textDisabled
                onActivated: root.pair()
            }
        }
    }

    Panels.ShellText {
        width: parent.width
        visible: root.problem !== "" || root.message !== ""
        leftPadding: 8
        text: root.problem !== "" ? root.problem : root.message
        wrapMode: Text.Wrap
        color: root.problem !== "" ? theme.red : theme.green
        font.pixelSize: root.appearance.textSize - 1
    }

    Item {
        objectName: "modeLink"

        signal activated()

        visible: !root.paired
        width: linkText.implicitWidth + 16
        height: linkText.implicitHeight + 4
        onActivated: root.useCode = !root.useCode

        Panels.ShellText {
            id: linkText

            x: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.useCode ? "Use a QR code" : "Use a pairing code"
            color: linkHover.hovered ? theme.accentHover : theme.accent
            font.pixelSize: root.appearance.textSize - 1
            font.underline: linkHover.hovered
        }

        HoverHandler {
            id: linkHover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: parent.activated()
        }
    }
}
