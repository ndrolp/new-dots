import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "." as Panels

// A choice between options in a compact selector: one hairline-bordered
// button showing the chosen option's label and a chevron, its border accent
// while hovered or open. Pressing it opens the options in a list below it,
// over whatever is there; the chosen one has accent text and a faint fill,
// and so does the one under the pointer. Choosing one, pressing outside or
// Esc closes the list. A `value` matching no option shows none. Choosing only
// asks: whoever owns the setting sets `value`.
Panels.SettingsHoverFill {
    id: control

    // Each option is { label, value }.
    property var options: []
    property var value
    readonly property bool open: list.opened
    readonly property var chosenOption: options.find(option => option.value === value) || null
    signal chosen(var value)

    implicitWidth: 128
    height: 32
    radius: appearance.radius
    color: hovering || open ? theme.cardHover : "transparent"
    border.color: hovering || open ? theme.accent : theme.border
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: control.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    Panels.ShellText {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: chevron.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: control.chosenOption ? control.chosenOption.label : ""
        color: theme.text
        elide: Text.ElideRight
        font.pixelSize: control.appearance.textSize - 1
    }

    Panels.ShellText {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: control.open ? "󰅃" : "󰅀"
        color: theme.textMuted
        font.pixelSize: control.appearance.textSize - 1
    }

    TapHandler {
        onTapped: list.opened ? list.close() : list.open()
    }

    Popup {
        id: list

        y: control.height + 4
        width: control.width
        padding: 4
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            radius: control.appearance.radius
            color: theme.background
            border.color: theme.border
            border.width: 1
        }

        contentItem: Column {
            spacing: 2

            Repeater {
                model: control.options

                delegate: Panels.SettingsHoverFill {
                    id: option

                    required property var modelData
                    readonly property bool isChosen: control.value === modelData.value

                    appearance: control.appearance
                    width: list.availableWidth
                    height: 28
                    radius: Math.max(0, control.radius - 2)
                    color: isChosen || hovering ? theme.cardHover : "transparent"

                    Panels.ShellText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.label
                        color: option.isChosen ? theme.accent : theme.text
                        elide: Text.ElideRight
                        font.pixelSize: control.appearance.textSize - 1
                    }

                    TapHandler {
                        onTapped: {
                            list.close();
                            control.chosen(option.modelData.value);
                        }
                    }
                }
            }
        }
    }
}
