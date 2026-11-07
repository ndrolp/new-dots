import QtQuick
import "../../config" as Config
import "../../services/QuickSwitch.js" as QuickSwitch
import "." as Panels

// The quick switch's choices and its keys, with no window of its own (QuickSwitch.qml is that). The
// selection belongs to modules/QuickSwitch.qml, because SUPER+P pressed again moves it too.
Column {
    id: root

    required property var appearance
    // What QuickSwitch.choices gives.
    property var choices: []
    property int currentIndex: 0

    signal selectionAsked(int index)
    signal chosen(var choice)
    signal closeAsked()

    function applyCurrent() {
        if (currentIndex < choices.length)
            chosen(choices[currentIndex]);
    }

    spacing: 10

    Config.Theme {
        id: theme
    }

    Keys.onEscapePressed: closeAsked()
    Keys.onReturnPressed: applyCurrent()
    Keys.onEnterPressed: applyCurrent()
    Keys.onDownPressed: selectionAsked(QuickSwitch.next(currentIndex, choices.length))
    Keys.onPressed: event => {
        if (event.key === Qt.Key_P) {
            selectionAsked(QuickSwitch.next(currentIndex, choices.length));
            event.accepted = true;
        }
    }

    Panels.PopupHeader {
        appearance: root.appearance
        icon: "󰍹"
        title: "Quick switch"
        subtitle: "P to move · Enter to apply"
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.choices

            delegate: Panels.PopupRow {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: index === root.currentIndex

                appearance: root.appearance
                width: parent.width
                height: 36
                color: selected || hovered ? theme.surfaceHover : "transparent"

                Panels.Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    elide: Text.ElideRight
                    color: row.selected ? theme.accent : theme.text
                    font.pixelSize: root.appearance.textSize + 1
                }

                TapHandler {
                    onTapped: root.chosen(row.modelData)
                }
            }
        }
    }
}
