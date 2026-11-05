import QtQuick
import "BarLayout.js" as BarLayout

// An icon and its value: side by side on a top or bottom bar, with the value
// underneath on a side bar.
ElementStack {
    id: root

    property string icon: ""
    property string value: ""
    property bool valueVisible: true
    property color iconColor: "white"
    property color valueColor: iconColor
    property int iconSize: 14
    property int valueSize: iconSize
    property int gap: 6

    spacing: vertical ? 0 : gap

    Text {
        id: iconText

        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
        font.bold: true
    }

    // As high as the icon beside it, so a smaller value stays centred on the
    // pixel an anchor puts it on.
    Item {
        visible: root.valueVisible
        width: valueText.width
        height: root.vertical ? valueText.height : iconText.height

        ElementText {
            id: valueText

            anchors.centerIn: parent
            appearance: root.appearance
            value: root.value
            color: root.valueColor
            font.pixelSize: root.valueSize
            font.bold: true
        }
    }
}
