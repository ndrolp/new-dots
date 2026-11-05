import QtQuick
import "../../config" as Config
import "../BarPosition.js" as BarPosition
import "../panels/PopupOutline.js" as PopupOutline
import "DockedZones.js" as DockedZones

// What a zone of the docked bar draws on. It has the outline of an attached
// popup: hanging from the screen edge the bar sits on, with small curved corners
// joining it to that edge and rounded corners away from it. A side on the
// screen's edge stays straight. While an attached popup hangs from the zone, it
// grows to receive it. Spans run along the bar, as with zones: left and right
// are the top and the bottom on a side bar.
Canvas {
    id: root

    // Appearance.motion (durations and easing), as the host has it.
    required property var motion
    // The screen edge the bar sits on.
    property string barPosition: "top"
    // How deep the bar is, from its screen edge inwards.
    required property real thickness
    // Where the zone sits while no popup is open.
    required property real spanLeft
    required property real spanRight
    // The attached popup hanging from this zone, { left, right }, or null.
    property var popup: null
    property color fillColor: "#313244"
    // The room beyond a zone's contents for the curves on that side.
    readonly property int sideWidth: 15
    readonly property real joinRadius: 6
    property bool keepLeftEdge: false
    property bool keepRightEdge: false
    readonly property var growth: DockedZones.growth({ left: spanLeft, right: spanRight },
        popup, joinRadius + theme.radius)
    // Only the growth animates, so the zone still follows its contents at once.
    property real growLeft: keepLeftEdge ? 0 : growth.left
    property real growRight: keepRightEdge ? 0 : growth.right
    readonly property bool sideBar: BarPosition.sideBar(barPosition)
    readonly property real zoneStart: spanLeft - growLeft
    readonly property real zoneLength: spanRight + growRight - zoneStart
    readonly property var path: PopupOutline.dockedPath({
        barPosition: barPosition,
        length: zoneLength,
        depth: thickness,
        radius: theme.radius,
        joinRadius: joinRadius,
        keepStart: keepLeftEdge,
        keepEnd: keepRightEdge
    })

    x: sideBar ? 0 : zoneStart
    y: sideBar ? zoneStart : 0
    width: sideBar ? thickness : zoneLength
    height: sideBar ? zoneLength : thickness

    Behavior on growLeft {
        NumberAnimation {
            duration: root.motion.medium
            easing.type: root.motion.easing
        }
    }

    Behavior on growRight {
        NumberAnimation {
            duration: root.motion.medium
            easing.type: root.motion.easing
        }
    }

    onPathChanged: requestPaint()
    onFillColorChanged: requestPaint()

    Config.Theme {
        id: theme
    }

    onPaint: {
        const context = getContext("2d");

        context.reset();
        context.fillStyle = fillColor;
        context.beginPath();
        context.moveTo(path.start.x, path.start.y);
        for (const segment of path.segments) {
            if (segment.controlX === undefined)
                context.lineTo(segment.x, segment.y);
            else
                context.quadraticCurveTo(segment.controlX, segment.controlY, segment.x, segment.y);
        }

        context.closePath();
        context.fill();
    }
}
