import QtQuick
import "../../config" as Config

// A thin bar filled up to a fraction between 0 and 1.
Rectangle {
    required property var appearance
    property real fraction: 0
    property color fillColor: theme.accent

    height: 4
    radius: 2
    color: theme.backgroundSecondary

    Config.Theme {
        id: theme
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, parent.fraction))
        height: parent.height
        radius: parent.radius
        color: parent.fillColor
    }
}
