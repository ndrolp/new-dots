import QtQuick
import "../panels" as Panels
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
    // What it shows: its icon, label and level (see OsdChange.display), or
    // null without a change.
    readonly property var display: change ? OsdChange.display(change) : null
    readonly property color toneColor: OsdChange.toneColor(display ? display.tone : "muted", theme)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    visible: display !== null

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.appearance.textSize + 10
            height: width
            radius: width / 2
            color: root.display && root.display.highlighted ? root.theme.accent : "transparent"

            ShellText {
                anchors.centerIn: parent
                text: root.display ? root.display.icon : ""
                color: root.display && root.display.highlighted ? root.theme.background : root.toneColor
                font.pixelSize: root.appearance.textSize + 2
                font.bold: true
            }
        }

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 240)
            text: root.display ? root.display.label : ""
            color: root.theme.text
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        Panels.ChangeLevel {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.display !== null && root.display.level !== null
            level: root.display && root.display.level !== null ? root.display.level : 0
            toneColor: root.toneColor
            appearance: root.appearance
            theme: root.theme
        }
    }
}
