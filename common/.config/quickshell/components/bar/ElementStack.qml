import QtQuick
import "BarLayout.js" as BarLayout

// What a bar element shows, in a row along a top or bottom bar and in a column
// down a side bar, where each part is centred across the bar.
Grid {
    id: root

    required property var appearance
    readonly property bool vertical: BarLayout.vertical(appearance)

    rows: vertical ? -1 : 1
    columns: vertical ? 1 : -1
    horizontalItemAlignment: Grid.AlignHCenter
}
