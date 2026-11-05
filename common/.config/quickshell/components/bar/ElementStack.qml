import QtQuick
import "../BarPosition.js" as BarPosition

// What a bar element shows, in a row along a top or bottom bar and in a column
// down a side bar, where each part is centred across the bar.
Grid {
    id: root

    required property var appearance
    readonly property bool sideBar: BarPosition.sideBar(appearance.barPosition)

    rows: sideBar ? -1 : 1
    columns: sideBar ? 1 : -1
    horizontalItemAlignment: Grid.AlignHCenter
}
