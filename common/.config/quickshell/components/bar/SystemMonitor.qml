import QtQuick
import "../../config" as Config

Rectangle {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var systemMonitor

    signal clicked()

    width: metrics.implicitWidth + 16
    height: appearance.barTransparent
        ? appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
        : Math.max(1, appearance.barHeight - (appearance.structuralVerticalPadding * 2))
    radius: appearance.radius
    color: hover.hovered ? theme.surfaceHover
        : appearance.pillsTransparent || appearance.transparentBarSlanted || root.grouped
            ? "transparent" : theme.surface

    border.width: appearance.barTransparentBorder && !root.grouped ? 1 : 0
    border.color: appearance.barTransparentBorder ? theme.border : "transparent"

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
