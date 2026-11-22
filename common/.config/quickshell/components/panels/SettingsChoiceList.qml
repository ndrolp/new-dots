import QtQuick
import "../../config" as Config
import "." as Panels

// A choice between more options than a SettingsChoice has room for: each its own hairline-bordered
// chip, wrapping onto new lines. The chosen one has accent text and a faint fill; the one under the
// pointer has the faint fill and an accent border. Choosing only asks:
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

        delegate: Panels.SettingsHoverFill {
            id: option

            required property var modelData
            readonly property bool isChosen: control.value === modelData.value

            appearance: control.appearance
            width: Math.min(optionLabel.implicitWidth + 20, control.width)
            height: 30
            radius: control.appearance.radius
            color: isChosen || hovering ? theme.cardHover : "transparent"
            border.color: hovering ? theme.accent : theme.border
            border.width: 1

            Behavior on border.color {
                ColorAnimation { duration: control.appearance.motion.short }
            }

            Panels.ShellText {
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
