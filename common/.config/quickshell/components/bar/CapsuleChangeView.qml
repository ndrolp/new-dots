import QtQuick
import "../panels/OsdChange.js" as OsdChange

// What a capsule shows instead of the OSD while a change shows: the OSD's
// icon, label and, for volume and brightness, level and percent, in one row
// as deep as the capsule.
Item {
    id: root

    // The change, as OsdChange.js describes it, or null.
    property var change: null
    // The bar's appearance, for its text size.
    required property var appearance
    // The colorscheme (config/Theme.qml).
    required property var theme
    readonly property var shown: change ? OsdChange.display(change) : null
    readonly property color toneColor: !shown ? theme.textMuted
        : shown.tone === "blue" ? theme.blue
        : shown.tone === "yellow" ? theme.yellow
        : shown.tone === "accent" ? theme.accent : theme.textMuted

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    visible: shown !== null

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.appearance.textSize + 10
            height: width
            radius: width / 2
            color: root.shown && root.shown.highlighted ? root.theme.accent : "transparent"

            ShellText {
                anchors.centerIn: parent
                text: root.shown ? root.shown.icon : ""
                color: root.shown && root.shown.highlighted ? root.theme.background : root.toneColor
                font.pixelSize: root.appearance.textSize + 2
                font.bold: true
            }
        }

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 240)
            text: root.shown ? root.shown.label : ""
            color: root.theme.text
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.shown !== null && root.shown.level !== null
            width: 96
            height: 6
            radius: 3
            color: root.theme.backgroundSecondary

            Rectangle {
                width: parent.width * (root.shown && root.shown.level !== null ? root.shown.level : 0)
                height: parent.height
                radius: parent.radius
                color: root.toneColor
            }
        }

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.shown !== null && root.shown.level !== null
            text: root.shown && root.shown.level !== null ? Math.round(root.shown.level * 100) + "%" : ""
            color: root.theme.textMuted
            font.pixelSize: root.appearance.textSize - 2
            font.bold: true
        }
    }
}
