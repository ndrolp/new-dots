import QtQuick
import "../BarPosition.js" as BarPosition
import "../StatusText.js" as StatusText
import "BarLayout.js" as BarLayout

// A short value in a bar element, as it comes on a top or bottom bar. On a side
// bar it stands upright (see StatusText.sideBarValue), centred, and shrinks if
// a line is still wider than the bar element.
Text {
    id: root

    required property var appearance
    property string value: ""
    readonly property bool sideBar: BarPosition.sideBar(appearance.barPosition)

    text: sideBar ? StatusText.sideBarValue(value) : value
    width: sideBar ? BarLayout.elementThickness(appearance) - 2 : undefined
    horizontalAlignment: sideBar ? Text.AlignHCenter : Text.AlignLeft
    fontSizeMode: sideBar ? Text.HorizontalFit : Text.FixedSize
    minimumPixelSize: 8
}
