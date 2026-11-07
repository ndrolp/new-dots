import QtQuick
import "../../config" as Config
import "." as Panels

// A choice between more options than a SettingsChoice has room for: each its own hairline-bordered
// chip, wrapping onto new lines. The chosen one has accent text and a faint fill. Choosing only asks:
// whoever owns the setting sets `value`.
Flow {
    id: control

    required property var appearance
    // Each option is { label, value }.
    property var options: []
    property var value
    signal chosen(var value)

    spacing: 6

    Config.Theme {
        id: theme
    }

    Repeater {
        model: control.options

        delegate: Rectangle {
            id: option

            required property var modelData
            readonly property bool isChosen: control.value === modelData.value

            width: Math.min(optionLabel.implicitWidth + 20, control.width)
            height: 30
            radius: control.appearance.radius
            color: isChosen ? theme.surfaceHover : "transparent"
            border.color: theme.border
            border.width: 1

            Panels.Text {
                id: optionLabel

                anchors.centerIn: parent
                width: Math.min(implicitWidth, option.width - 20)
                elide: Text.ElideRight
                text: option.modelData.label
                color: option.isChosen ? theme.accent : theme.text
                font.pixelSize: control.appearance.textSize - 1
            }

            TapHandler {
                onTapped: control.chosen(option.modelData.value)
            }
        }
    }
}
