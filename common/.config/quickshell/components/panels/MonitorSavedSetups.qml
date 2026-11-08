import QtQuick
import "." as Panels

// The saved monitor setups, each named after its monitors, with Forget as the only action. Forget
// only asks, and waits out a change being tried out, which rewrites the same file.
Column {
    id: root

    required property var appearance
    // As Services.MonitorSetups.savedSetups gives them.
    property var setups: []
    property bool canForget: true
    signal forgetAsked(string combination)

    width: parent ? parent.width : 0
    spacing: 6
    visible: setups.length > 0

    Panels.SettingsHeading {
        width: parent.width
        appearance: root.appearance
        text: "Saved setups"
        topPadding: 4
    }

    Repeater {
        model: root.setups

        delegate: Item {
            id: row

            required property var modelData
            readonly property string setupName: modelData.name

            width: root.width
            height: forget.height

            Panels.ShellText {
                anchors.left: parent.left
                anchors.right: forget.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.setupName
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize
            }

            Panels.SettingsButton {
                id: forget

                anchors.right: parent.right
                appearance: root.appearance
                label: "Forget"
                enabled: root.canForget
                onActivated: root.forgetAsked(row.modelData.combination)
            }
        }
    }
}
