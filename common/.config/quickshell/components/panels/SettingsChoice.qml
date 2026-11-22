import QtQuick
import "../../config" as Config
import "." as Panels

// A segmented choice between a few options: one hairline-bordered control
// split evenly between them, its border accent while hovered. The chosen
// option has accent text and a faint fill, and so does the option under the
// pointer; a `value` matching no option marks none. Choosing only asks: whoever
// owns the setting sets `value`.
Rectangle {
    id: control

    required property var appearance
    // Each option is { label, value }.
    property var options: []
    property var value
    // Follows the pointer; settable so its look can be checked without one.
    property bool hovered: controlHover.hovered
    signal chosen(var value)

    height: 32
    radius: appearance.radius
    color: "transparent"
    border.color: hovered ? theme.accent : theme.border
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: control.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: controlHover
    }

    Row {
        anchors.fill: parent
        anchors.margins: control.border.width

        Repeater {
            model: control.options

            delegate: Rectangle {
                id: option

                required property var modelData
                readonly property bool isChosen: control.value === modelData.value
                property bool hovered: optionHover.hovered

                width: parent.width / control.options.length
                height: parent.height
                radius: Math.max(0, control.radius - control.border.width)
                color: isChosen || hovered ? theme.cardHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: control.appearance.motion.short }
                }

                HoverHandler {
                    id: optionHover

                    cursorShape: Qt.PointingHandCursor
                }

                Panels.ShellText {
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 8)
                    text: option.modelData.label
                    color: option.isChosen ? theme.accent : theme.text
                    elide: Text.ElideRight
                    font.pixelSize: control.appearance.textSize - 1
                }

                TapHandler {
                    onTapped: control.chosen(option.modelData.value)
                }
            }
        }
    }
}
