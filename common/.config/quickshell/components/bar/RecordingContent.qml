import QtQuick
import "../BarPosition.js" as BarPosition
import "BarLayout.js" as BarLayout

// What the recording bar element shows: its icon and the elapsed time or, for a
// moment, which apps share the screen. The time stands like any short value on
// a side bar. The apps are free text, so there they run sideways with an
// ellipsis, like other long text, and the icon stays upright.
Item {
    id: root

    required property var appearance
    property color iconColor: "white"
    property string elapsed: ""
    // Which apps share the screen; empty shows the time.
    property string sharing: ""
    // How long the apps' text may get running sideways.
    property real maximumLength: 260
    readonly property bool sideways: BarPosition.sideBar(appearance.barPosition) && sharing !== ""

    implicitWidth: sideways ? sidewaysRow.implicitHeight : value.implicitWidth
    implicitHeight: sideways ? sidewaysRow.implicitWidth : value.implicitHeight

    IconValue {
        id: value

        anchors.centerIn: parent
        visible: !root.sideways
        appearance: root.appearance
        gap: 5
        icon: "󰑋"
        iconColor: root.iconColor
        iconSize: root.appearance.iconSize
        value: root.sharing !== "" ? root.sharing : root.elapsed
        valueSize: root.appearance.textSize - 2
    }

    Row {
        id: sidewaysRow

        anchors.centerIn: parent
        visible: root.sideways
        spacing: 5
        rotation: BarLayout.turn(root.appearance)

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            rotation: -parent.rotation
            text: value.icon
            color: root.iconColor
            font.pixelSize: root.appearance.iconSize
            font.bold: true
        }

        ShellText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(root.maximumLength, implicitWidth)
            text: root.sharing
            color: root.iconColor
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize - 2
            font.bold: true
        }
    }
}
