import QtQuick
import "../../config" as Config
import "." as Panels

// A segmented choice between a few options: one hairline-bordered control
// split evenly between them. The chosen option has accent text and a faint
// fill; a `value` matching no option marks none. Choosing only asks: whoever
// owns the setting sets `value`.
Rectangle {
    id: control

    required property var appearance
    // Each option is { label, value }.
    property var options: []
    property var value
    signal chosen(var value)

    height: 32
    radius: appearance.radius
    color: "transparent"
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
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

                width: parent.width / control.options.length
                height: parent.height
                radius: Math.max(0, control.radius - control.border.width)
                color: isChosen ? theme.surfaceHover : optionHover.hovered ? Qt.rgba(theme.surfaceHover.r,
                    theme.surfaceHover.g, theme.surfaceHover.b, 0.5) : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                HoverHandler {
                    id: optionHover
                }

                Panels.Text {
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
