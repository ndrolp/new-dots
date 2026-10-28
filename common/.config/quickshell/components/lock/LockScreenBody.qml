import QtQuick
import QtQuick.Effects
import "../../config" as Config

// What the lock screen shows on one monitor: its wallpaper blurred behind
// the clock and the date and, on the focused monitor only, the password field with what went wrong under
// it. Enter only asks for the password to be checked (passwordSubmitted) and
// clears the field: Lock.qml checks it.
Rectangle {
    id: root

    property date now: new Date()
    // The monitor's wallpaper, as a local path; "" shows only the theme.
    property string wallpaper: ""
    property bool showsPasswordField: false
    // A password is being checked: the field takes no more until it's done.
    property bool checking: false
    property string error: ""
    signal passwordSubmitted(string password)

    color: theme.background

    Config.Theme {
        id: theme
    }

    Image {
        id: wallpaperImage

        anchors.fill: parent
        source: root.wallpaper === "" ? "" : "file://" + root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaperImage
        visible: root.wallpaper !== ""
        blurEnabled: true
        blur: 1
        blurMax: 64
    }

    // Keeps the theme's text readable on light and dark wallpapers alike.
    Rectangle {
        anchors.fill: parent
        color: theme.background
        opacity: 0.55
        visible: root.wallpaper !== ""
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "HH:mm")
            color: theme.text
            font.family: theme.fontFamily
            font.pixelSize: 96
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, MMMM d")
            color: theme.textMuted
            font.family: theme.fontFamily
            font.pixelSize: 22
        }

        Item {
            width: 1
            height: 28
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 44
            radius: theme.radius
            color: theme.backgroundSecondary
            border.width: 1
            border.color: root.error !== "" ? theme.red : password.activeFocus ? theme.accent : theme.border
            visible: root.showsPasswordField

            TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                readOnly: root.checking
                focus: root.showsPasswordField
                color: theme.text
                font.family: theme.fontFamily
                font.pixelSize: 16
                clip: true

                onAccepted: {
                    if (root.checking)
                        return;
                    const typed = text;
                    text = "";
                    root.passwordSubmitted(typed);
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.checking ? "Checking…" : "Password"
                    color: theme.textDisabled
                    font: password.font
                    visible: password.text === ""
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.error
            color: theme.red
            font.family: theme.fontFamily
            font.pixelSize: 14
            visible: root.showsPasswordField && root.error !== ""
        }
    }
}
