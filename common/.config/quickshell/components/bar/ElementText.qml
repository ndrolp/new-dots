import QtQuick
import "../StatusText.js" as StatusText
import "BarLayout.js" as BarLayout

// A short value in a bar element, as it comes on a top or bottom bar. On a side
// bar it stands upright (see StatusText.sideBarValue), centred, and shrinks if
// a line is still wider than the bar element.
Text {
    id: root

    required property var appearance
    property string value: ""
    readonly property bool vertical: BarLayout.vertical(appearance)

    text: vertical ? StatusText.sideBarValue(value) : value
    width: vertical ? BarLayout.elementThickness(appearance) - 2 : undefined
    horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
    fontSizeMode: vertical ? Text.HorizontalFit : Text.FixedSize
    minimumPixelSize: 8
}
