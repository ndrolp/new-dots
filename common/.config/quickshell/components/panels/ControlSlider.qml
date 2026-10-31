import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "." as Panels

// A slider of the control center: its icon and label, its value on the
// right, over a track filled in its color up to the value.
Column {
    id: control

    required property var appearance
    required property string label
    required property string icon
    required property color accentColor
    property string valueText: ""
    property alias from: slider.from
    property alias to: slider.to
    property alias value: slider.value

    signal adjusted(real position)

    spacing: 4

    Config.Theme {
        id: sliderTheme
    }

    Item {
        width: parent.width
        height: Math.max(sliderLabel.implicitHeight, sliderValue.implicitHeight)

        Panels.Text {
            id: sliderLabel

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: control.icon + "  " + control.label
            color: sliderTheme.text
            font.pixelSize: control.appearance.textSize - 1
        }

        PopupLabel {
            id: sliderValue

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            appearance: control.appearance
            text: control.valueText
        }
    }

    Slider {
        id: slider

        width: parent.width
        implicitHeight: 18
        onMoved: control.adjusted(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + (slider.availableHeight - height) / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: sliderTheme.backgroundSecondary

            Rectangle {
                width: parent.width * slider.visualPosition
                height: parent.height
                radius: parent.radius
                color: control.accentColor
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + (slider.availableHeight - height) / 2
            width: 12
            height: 12
            radius: width / 2
            color: control.accentColor
        }
    }
}
