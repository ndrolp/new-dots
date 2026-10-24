import QtQuick

// Short controls two per line, in two columns of equal width; each control
// sets its width to `cellWidth`. Lists and anything that grows stay outside,
// full width.
Grid {
    readonly property real cellWidth: Math.max(0, (width - columnSpacing) / 2)

    width: parent ? parent.width : 0
    columns: 2
    columnSpacing: 24
    rowSpacing: 14
}
