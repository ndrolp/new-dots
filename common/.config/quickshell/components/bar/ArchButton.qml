import QtQuick
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    property bool active: false

    signal clicked()

    width: appearance.workspaceButtonSize + (appearance.archButtonHorizontalPadding * 2)
    height: appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
    radius: appearance.radius
    color: hover.hovered ? theme.surfaceHover
        : appearance.pillsTransparent || appearance.transparentBarSlanted ? "transparent" : theme.surface

    Behavior on color {
        ColorAnimation {
            duration: 140
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
