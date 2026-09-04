import QtQuick
import QtQuick.Controls
import "../../config" as Config

Slider {
    id: control

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: theme.backgroundSecondary

        Rectangle {
            width: parent.width * control.visualPosition
            height: parent.height
            radius: parent.radius
            color: theme.accent
        }
    }

    Config.Theme {
        id: theme
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 14
        height: 14
        radius: 7
        color: theme.accent
    }
}
