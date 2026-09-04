import QtQuick
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    required property var systemMonitor

    signal clicked()

    width: metrics.implicitWidth + 16
    height: appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
    radius: appearance.radius
    color: hover.hovered ? theme.surfaceHover
        : appearance.pillsTransparent || appearance.transparentBarSlanted || appearance.statusIsland
            ? "transparent" : theme.surface

    Config.Theme {
        id: theme
    }

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Row {
        id: metrics

        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰍛 " + Math.round(root.systemMonitor.cpuUsage) + "%"
            color: theme.blue
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        Text {
            text: "󰘚 " + Math.round(root.systemMonitor.memoryUsage) + "%"
            color: theme.yellow
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        Text {
            text: " " + (root.systemMonitor.temperature > 0
                ? Math.round(root.systemMonitor.temperature) + "°" : "--")
            color: theme.orange
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
