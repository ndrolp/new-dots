import QtQuick
import "../../config" as Config
import "../panels/PopupOutline.js" as PopupOutline
import "DockedZones.js" as DockedZones

// What a zone of the docked bar draws on. It has the outline of an attached
// popup: hanging from the top of the screen, with small curved corners joining
// it to that edge and rounded bottom corners. A side on the screen's edge stays
// straight. While an attached popup hangs from the zone, it grows to receive it.
Canvas {
    id: root

    // Appearance.motion (durations and easing), as the host has it.
    required property var motion
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
    readonly property var corners: PopupOutline.attachedCorners({
        width: width,
        height: height,
        radius: theme.radius,
        joinRadius: joinRadius
    })
    readonly property real edgeLeft: keepLeftEdge ? 0 : corners.join
    readonly property real edgeRight: keepRightEdge ? width : width - corners.join

    x: spanLeft - growLeft
    width: spanRight + growRight - x

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

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()

    Config.Theme {
        id: theme
    }

    onPaint: {
        const context = getContext("2d");
        const join = corners.join;
        const bottom = corners.bottom;

        context.reset();
        context.fillStyle = fillColor;
        context.beginPath();
        context.moveTo(0, 0);
        context.lineTo(width, 0);
        if (keepRightEdge) {
            context.lineTo(width, height);
        } else {
            context.quadraticCurveTo(edgeRight, 0, edgeRight, join);
            context.lineTo(edgeRight, height - bottom);
            context.quadraticCurveTo(edgeRight, height, edgeRight - bottom, height);
        }
        if (keepLeftEdge) {
            context.lineTo(0, height);
        } else {
            context.lineTo(edgeLeft + bottom, height);
            context.quadraticCurveTo(edgeLeft, height, edgeLeft, height - bottom);
            context.lineTo(edgeLeft, join);
            context.quadraticCurveTo(edgeLeft, 0, 0, 0);
        }

        context.closePath();
        context.fill();
    }
}
