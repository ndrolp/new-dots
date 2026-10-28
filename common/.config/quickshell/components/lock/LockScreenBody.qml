import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "../../config/Motion.js" as Motion

// What the lock screen shows on one monitor: its wallpaper blurred behind
// the clock and the date and, on the focused monitor only, the password field with what went wrong under
// it. Enter only asks for the password to be checked (passwordSubmitted) and
// clears the field: Lock.qml checks it.
// When it locks the wallpaper blurs in and the clock rises into place;
// unlocking plays it backwards, so the lock screen gives way to the desktop
// under it. A wrong password shakes the field.
Rectangle {
    id: root

    property date now: new Date()
    // The monitor's wallpaper, as a local path; "" shows only the theme.
    property string wallpaper: ""
    property bool showsPasswordField: false
    // A password is being checked: the field takes no more until it's done.
    property bool checking: false
    property string error: ""
    // The right password went through: the lock screen fades away.
    property bool unlocking: false
    // Appearance.motion; reduce motion shows and hides it at once.
    property var motion: Motion.motion(false)
    readonly property bool shaking: shake.running
    signal passwordSubmitted(string password)

    // Turns true once it's on screen, so locking animates in.
    property bool revealed: false
    readonly property bool showing: revealed && !unlocking

    Component.onCompleted: revealed = true

    onErrorChanged: {
        if (error !== "" && motion.short > 0)
            shake.restart();
    }

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
        blur: root.showing ? 1 : 0
        blurMax: 64

        Behavior on blur {
            NumberAnimation {
                duration: root.motion.long
                easing.type: root.motion.easing
            }
        }
    }

    // Keeps the theme's text readable on light and dark wallpapers alike.
    Rectangle {
        anchors.fill: parent
        color: theme.background
        opacity: root.showing ? 0.55 : 0
        visible: root.wallpaper !== ""

        Behavior on opacity {
            NumberAnimation {
                duration: root.motion.long
                easing.type: root.motion.easing
            }
        }
    }

    Column {
        objectName: "lockContent"
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.showing ? 0 : 24
        spacing: 12
        opacity: root.showing ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.motion.long
                easing.type: root.motion.easing
            }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: root.motion.long
                easing.type: root.motion.easing
            }
        }

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
            transform: Translate {
                id: shakeOffset
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: root.motion.short
                    easing.type: root.motion.easing
                }
            }

            SequentialAnimation {
                id: shake

                NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: root.motion.short / 4 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: root.motion.short / 2 }
                NumberAnimation { target: shakeOffset; property: "x"; to: -6; duration: root.motion.short / 2 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: root.motion.short / 4 }
            }

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
