import QtQuick
import "../../config" as Config
import "../bar/PrivacyIndicator.js" as PrivacyIndicator

// What the privacy indicator's popup shows: under each device kind in use,
// the microphone and the camera, the apps using it
// (PrivacyIndicator.sections). Kept apart from the popup window so it is
// tested without Quickshell.
Column {
    id: root

    required property var appearance
    // The apps using the microphone or a camera (services/DeviceCaptures.qml).
    required property var deviceCaptures

    readonly property var sections: PrivacyIndicator.sections(deviceCaptures.captures)

    spacing: 10

    Config.Theme {
        id: theme
    }

    // The popup may still be open as the last app stops.
    PopupLabel {
        appearance: root.appearance
        visible: root.sections.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Nothing uses the microphone or a camera"
    }

    Repeater {
        model: root.sections

        delegate: Column {
            required property var modelData

            width: root.width
            spacing: 4

            PopupHeader {
                appearance: root.appearance
                icon: modelData.icon
                iconColor: theme.orange
                title: modelData.title
            }

            Repeater {
                model: modelData.apps

                delegate: ShellText {
                    required property string modelData

                    width: root.width
                    leftPadding: root.appearance.textSize + 15
                    elide: Text.ElideRight
                    color: theme.text
                    font.pixelSize: root.appearance.textSize
                    text: modelData
                }
            }
        }
    }
}
