import QtQuick

// A change's level, as the OSD and the capsule show it for volume and
// brightness: a bar filled to it in the change's tone, and its percent.
// Stacked (the OSD), the percent goes under the bar; otherwise (the capsule)
// beside it.
Grid {
    id: root

    // The level, 0 to 1 (see OsdChange.display).
    property real level: 0
    // The colour the bar fills in (see OsdChange.toneColor).
    property color toneColor
    // The bar's appearance, for its text size.
    required property var appearance
    // The colorscheme (config/Theme.qml).
    required property var theme
    // Whether the percent goes under the bar rather than beside it.
    property bool stacked: false
    // How long the bar is, in px.
    property real barWidth: 96

    columns: stacked ? 1 : 2
    rowSpacing: 6
    columnSpacing: 8
    verticalItemAlignment: Grid.AlignVCenter

    Rectangle {
        width: root.barWidth
        height: 6
        radius: 3
        color: root.theme.backgroundSecondary

        Rectangle {
            width: parent.width * root.level
            height: parent.height
            radius: parent.radius
            color: root.toneColor
        }
    }

    ShellText {
        text: Math.round(root.level * 100) + "%"
        color: root.theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
    }
}
