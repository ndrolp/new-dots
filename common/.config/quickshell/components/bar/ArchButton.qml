import QtQuick
import "../../config" as Config
import "BarLayout.js" as BarLayout

Rectangle {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    property bool active: false

    signal clicked()

    readonly property var size: BarLayout.size(appearance,
        appearance.workspaceButtonSize + (appearance.archButtonHorizontalPadding * 2),
        BarLayout.elementThickness(appearance))

    width: size.width
    height: size.height
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
