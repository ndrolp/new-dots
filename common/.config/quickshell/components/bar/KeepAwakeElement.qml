import QtQuick
import "../../config" as Config
import "../../services/KeepAwakeState.js" as KeepAwakeState

// The keep-awake bar element: a cup, filled and green while keep-awake is on,
// an outline in the subtext color while it is off. A click asks for the
// keep-awake popup.
Rectangle {
    id: root

    required property var appearance
    // The shell's keep-awake (services/KeepAwake.qml).
    required property var keepAwake
    // Whether the element sits in a group, which draws its background.
    property bool grouped: false
    signal popupRequested()

    width: keepAwakeIcon.width + 16
    radius: appearance.radius
    color: keepAwakeHover.hovered ? theme.surfaceHover
        : grouped || appearance.pillsTransparent || appearance.transparentBarSlanted
            ? "transparent" : theme.surface
    border.width: appearance.barTransparentBorder && !grouped ? 1 : 0
    border.color: appearance.barTransparentBorder ? theme.border : "transparent"

    Behavior on color {
        ColorAnimation { duration: root.appearance.motion.short }
    }

    Config.Theme {
        id: theme
    }

    HoverHandler {
        id: keepAwakeHover
    }

    TextMetrics {
        id: onCup

        font: keepAwakeIcon.font
        text: KeepAwakeState.cups.on
    }

    TextMetrics {
        id: offCup

        font: keepAwakeIcon.font
        text: KeepAwakeState.cups.off
    }

    Text {
        id: keepAwakeIcon

        anchors.centerIn: parent
        // As wide as the wider cup, so turning keep-awake on or off doesn't
        // move the elements next to it.
        width: Math.ceil(Math.max(onCup.advanceWidth, offCup.advanceWidth))
        horizontalAlignment: Text.AlignHCenter
        text: KeepAwakeState.cup(root.keepAwake.on)
        color: root.keepAwake.on ? theme.green : theme.textMuted
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.popupRequested()
    }
}
