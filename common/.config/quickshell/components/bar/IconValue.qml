import QtQuick

// An icon and its value: side by side on a top or bottom bar, with the value
// underneath on a side bar. A `lead`, if any, comes right before the value in
// its own colour (the expanded capsule's clock shows its date so).
ElementStack {
    id: root

    property string icon: ""
    property string value: ""
    property string lead: ""
    property color leadColor: valueColor
    property bool iconVisible: true
    property bool valueVisible: true
    property color iconColor: "white"
    property color valueColor: iconColor
    property int iconSize: 14
    property int valueSize: iconSize
    property int gap: 6

    spacing: sideBar ? 0 : gap

    ShellText {
        id: iconText

        visible: root.iconVisible
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
        font.bold: true
    }

    // As high as the icon beside it, so a smaller value stays centred on the
    // pixel an anchor puts it on.
    Item {
        visible: root.valueVisible
        width: leadText.width + valueText.width
        height: root.sideBar ? valueText.height : iconText.height

        ElementText {
            id: valueText

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            appearance: root.appearance
            value: root.value
            color: root.valueColor
            font.pixelSize: root.valueSize
            font.bold: true
        }

        // After the value, so the value stays this slot's first child.
        ElementText {
            id: leadText

            visible: root.lead !== ""
            width: visible ? implicitWidth : 0
            anchors.verticalCenter: parent.verticalCenter
            appearance: root.appearance
            value: root.lead
            color: root.leadColor
            font.pixelSize: root.valueSize
            font.bold: true
        }
    }
}
