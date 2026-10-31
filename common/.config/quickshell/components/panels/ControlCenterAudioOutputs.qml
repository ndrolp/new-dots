import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The expanded control center's audio output subpage: a back arrow, then
// the audio outputs with the one sound plays through marked. Choosing one
// asks the host to switch to it (`outputChosen`); the subpage stays, so the
// mark moves. The host hands it the outputs, so it needs no Pipewire.
Column {
    id: page

    required property var appearance
    // The audio outputs (PwNode sinks, or anything AudioOutputs.js can name).
    property var outputs: []
    // The output sound plays through now.
    property var current: null

    signal outputChosen(var output)
    // The back arrow: back to the expanded control center.
    signal backRequested()

    spacing: 4

    Config.Theme {
        id: theme
    }

    Item {
        width: parent.width
        height: 34

        Panels.PopupButton {
            id: backArrow

            objectName: "backArrow"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            appearance: page.appearance
            label: "󰁍"
            labelSize: page.appearance.textSize + 3

            onActivated: page.backRequested()
        }

        Panels.PopupTitle {
            anchors.left: backArrow.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            appearance: page.appearance
            text: "Audio output"
        }
    }

    Panels.PopupLabel {
        objectName: "noAudioOutputs"
        width: parent.width
        visible: page.outputs.length === 0
        appearance: page.appearance
        text: "No audio outputs found"
    }

    Column {
        objectName: "audioOutputList"
        width: parent.width
        spacing: 2

        Repeater {
            model: page.outputs

            delegate: Panels.PopupRow {
                id: row

                required property var modelData
                readonly property var output: modelData
                readonly property bool active: page.current === output

                function choose() {
                    page.outputChosen(row.output);
                }

                objectName: "audioOutputRow"
                appearance: page.appearance
                width: parent.width
                height: outputName.rowHeight

                Panels.Text {
                    id: outputIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: StatusText.audioOutputIcon(row.output)
                    color: row.active ? theme.accent : theme.textMuted
                    font.pixelSize: page.appearance.textSize + 3
                }

                Panels.AudioOutputName {
                    id: outputName

                    anchors.left: outputIcon.right
                    anchors.leftMargin: 10
                    anchors.right: activeMark.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    appearance: page.appearance
                    output: row.output
                    highlighted: row.active
                }

                Panels.Text {
                    id: activeMark

                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰄬"
                    visible: row.active
                    color: theme.accent
                    font.pixelSize: page.appearance.textSize + 1
                }

                TapHandler {
                    onTapped: row.choose()
                }
            }
        }
    }
}
