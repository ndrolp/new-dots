import QtQuick
import "../../config" as Config
import "../../services/KeepAwakeState.js" as KeepAwakeState
import "BarLayout.js" as BarLayout
import "../../config/BarProfileModel.js" as BarProfileModel

// The keep-awake bar element: a cup, filled and green while keep-awake is on,
// an outline in the subtext color while it is off. As a capsule's live
// element, a countdown's time left shows beside the cup, coarsely and once a
// minute (KeepAwakeState.coarseTimeLeft); on any other bar style it doesn't.
// A click asks for the keep-awake popup.
Rectangle {
    id: root

    required property var appearance
    // The shell's keep-awake (services/KeepAwake.qml).
    required property var keepAwake
    // Whether the element sits in a group, which draws its background.
    property bool grouped: false
    // The sizes it is drawn at, { iconSize, thickness }: the profile's, or a
    // live element's (LiveElements.elementSizes).
    property var sizes: ({ iconSize: appearance.iconSize, textSize: appearance.textSize, thickness: BarLayout.elementThickness(appearance) })
    // Whether it is drawn as a capsule's live element, beside the pills.
    property bool live: false
    // Whether the time left shows beside the cup: only on a live element
    // while a countdown runs, never "until turned off".
    readonly property bool timeLeftShown: live && keepAwake.timed
    // The whole minutes left on the countdown: the time left's label
    // depends on these, which change once a minute, not on secondsLeft.
    readonly property int minutesLeft: KeepAwakeState.minutesLeft(keepAwake.secondsLeft)
    signal popupRequested()

    readonly property var size: BarLayout.size(appearance, content.width + 16, sizes.thickness)

    width: size.width
    height: size.height
    radius: appearance.radius
    color: keepAwakeHover.hovered ? theme.surfaceHover
        : grouped || !BarProfileModel.elementPillsDrawn(appearance)
            ? "transparent" : theme.surface
    border.width: BarProfileModel.elementBorderDrawn(appearance) && !grouped ? 1 : 0
    border.color: appearance.elementBorder ? theme.border : "transparent"

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

    // The cup, and the time left after it when shown. Its width is worked
    // out here rather than by a Row, whose layout lags behind.
    Item {
        id: content

        readonly property int gap: 6

        anchors.centerIn: parent
        width: keepAwakeIcon.width + (root.timeLeftShown ? gap + timeLeft.implicitWidth : 0)
        height: Math.max(keepAwakeIcon.height, timeLeft.height)

        ShellText {
            id: keepAwakeIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            // As wide as the wider cup, so turning keep-awake on or off doesn't
            // move the elements next to it.
            width: Math.ceil(Math.max(onCup.advanceWidth, offCup.advanceWidth))
            horizontalAlignment: Text.AlignHCenter
            text: KeepAwakeState.cup(root.keepAwake.on)
            color: root.keepAwake.on ? theme.green : theme.textMuted
            font.pixelSize: root.sizes.iconSize
            font.bold: true
        }

        // Worked out from minutesLeft, so only once a minute, though
        // secondsLeft ticks every second.
        ShellText {
            id: timeLeft

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.timeLeftShown
            text: root.timeLeftShown ? KeepAwakeState.coarseTimeLeft(root.minutesLeft) : ""
            color: theme.green
            font.pixelSize: root.sizes.textSize
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.popupRequested()
    }
}
