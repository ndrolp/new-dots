import QtQuick
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    property bool active: false

    signal clicked()

    width: appearance.workspaceButtonSize + (appearance.archButtonHorizontalPadding * 2)
    height: appearance.barTransparent
        ? appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
        : Math.max(1, appearance.barHeight - (appearance.elementVerticalPadding * 2))
    radius: appearance.radius
    color: hover.hovered ? theme.surfaceHover
        : appearance.pillsTransparent || appearance.transparentBarSlanted || root.grouped
            ? "transparent" : theme.surface

    border.width: appearance.barTransparentBorder && !root.grouped ? 1 : 0
    border.color: appearance.barTransparentBorder ? theme.border : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: root.appearance.motion.short
        }
    }

    Config.Theme {
        id: theme
    }

    Text {
        anchors.centerIn: parent
        text: ""
        color: theme.purple
        font.pixelSize: appearance.textSize + 4
        font.bold: true
    }

    HoverHandler {
        id: hover
    }

    Item {
        anchors.fill: parent

        TapHandler {
            onTapped: root.clicked()
        }
    }

}
