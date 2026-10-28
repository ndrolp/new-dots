import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The audio popup: the audio outputs, to choose where sound plays.
BarPopup {
    id: root

    popup: "audio"
    implicitWidth: 440

    // Binds the outputs, so their descriptions and default are known.
    Config.Theme {
        id: theme
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    Column {
        width: parent.width
        spacing: 4

        PopupHeader {
            appearance: root.appearance
            icon: "󰓃"
            iconColor: theme.accent
            title: "Audio output"
            subtitle: "Choose where sound plays"
        }

        Item {
            width: 1
            height: 4
        }

        Repeater {
            model: Pipewire.nodes.values

            delegate: PopupRow {
                required property var modelData

                readonly property bool selected: Pipewire.defaultAudioSink === modelData

                appearance: root.appearance
                visible: modelData.isSink
                width: parent.width
                height: outputName.rowHeight

                Panels.Text {
                    id: sinkIconLabel

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: StatusText.audioOutputIcon(modelData)
                    color: parent.selected ? theme.accent : theme.textMuted
                    font.pixelSize: 16
                }

                Panels.AudioOutputName {
                    id: outputName

                    anchors.left: sinkIconLabel.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    appearance: root.appearance
                    output: modelData
                    highlighted: parent.selected
                    labelSize: root.appearance.textSize - 1
                }

                TapHandler {
                    onTapped: {
                        Pipewire.preferredDefaultAudioSink = modelData;
                        root.popups.audioSinkSelected(modelData);
                        root.popups.popupClosed("audio");
                    }
                }
            }
        }
    }
}
