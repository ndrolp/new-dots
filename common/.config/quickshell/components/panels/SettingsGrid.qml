import QtQuick

// Short controls two per line, in two columns of equal width; each control
// sets its width to `cellWidth`. When a cell would be narrower than
// `minimumCellWidth`, too narrow to hold a label and its control side by
// side, the grid is one column instead and each control takes the whole
// width. Lists and anything that grows stay outside, full width.
Grid {
    property real minimumCellWidth: 220
    readonly property real cellWidth: columns === 2 ? Math.max(0, (width - columnSpacing) / 2) : width

    width: parent ? parent.width : 0
    columns: (width - columnSpacing) / 2 >= minimumCellWidth ? 2 : 1
    columnSpacing: 24
    rowSpacing: 14
}
