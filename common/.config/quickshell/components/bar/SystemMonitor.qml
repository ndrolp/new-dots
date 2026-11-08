import QtQuick
import "../../config" as Config
import "BarLayout.js" as BarLayout

Rectangle {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var systemMonitor

    signal clicked()

    readonly property var size: BarLayout.size(appearance,
        BarLayout.itemLength(appearance, { width: metrics.implicitWidth, height: metrics.implicitHeight }) + 16,
        BarLayout.elementThickness(appearance))

    width: size.width
    height: size.height
    radius: appearance.radius
    color: hover.hovered ? theme.surfaceHover
        : appearance.pillsTransparent || appearance.transparentBarSlanted || root.grouped
            ? "transparent" : theme.surface

    border.width: appearance.elementBorder && !root.grouped ? 1 : 0
    border.color: appearance.elementBorder ? theme.border : "transparent"

    Config.Theme {
        id: theme
    }

    Behavior on color {
        ColorAnimation { duration: root.appearance.motion.short }
    }

    ElementStack {
        id: metrics

        anchors.centerIn: parent
        appearance: root.appearance
        spacing: 8

        ElementText {
            appearance: root.appearance
            value: "󰍛 " + Math.round(root.systemMonitor.cpuUsage) + "%"
            color: theme.blue
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ElementText {
            appearance: root.appearance
            value: "󰘚 " + Math.round(root.systemMonitor.memoryUsage) + "%"
            color: theme.yellow
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ElementText {
            appearance: root.appearance
            value: " " + (root.systemMonitor.temperature > 0
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
