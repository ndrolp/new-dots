import QtQuick
import "../../config" as Config
import "../BarPosition.js" as BarPosition
import "../panels/PopupOutline.js" as PopupOutline
import "DockedZones.js" as DockedZones

// What a zone of the docked bar draws on. It has the outline of an attached
// popup: hanging from the screen edge the bar sits on, with small curved corners
// joining it to that edge and rounded corners away from it. A side on the
// screen's edge stays straight. While an attached popup hangs from the zone, it
// grows to receive it. Spans run along the bar: they start at its left, or at
// its top on a side bar. With the bar border on, a hairline runs along the zone,
// except on the screen's edge, and round the popup hanging from it.
Canvas {
    id: root

    // Appearance.motion (durations and easing), as the host has it.
    required property var motion
    // The screen edge the bar sits on.
    property string barPosition: "top"
    // How deep the bar is, from its screen edge inwards.
    required property real thickness
    // Where the zone sits while no popup is open.
    required property real spanStart
    required property real spanEnd
    // The attached popup hanging from this zone, { start, end, resizing }, or
    // null. While it resizes the zone keeps up with it frame by frame.
    property var popup: null
    property color fillColor: "#313244"
    // Draws the bar border.
    property bool border: false
    property color borderColor: theme.border
    // The room beyond a zone's contents for the curves at that end.
    readonly property int endWidth: 15
    readonly property real joinRadius: 6
    property bool keepStart: false
    property bool keepEnd: false
    readonly property var growth: DockedZones.growth({ start: spanStart, end: spanEnd },
        popup, joinRadius + theme.radius)
    // Only the growth animates, so the zone still follows its contents at once.
    property real growStart: keepStart ? 0 : growth.start
    property real growEnd: keepEnd ? 0 : growth.end
    readonly property bool growthAnimated: !(popup && popup.resizing)
    readonly property bool sideBar: BarPosition.sideBar(barPosition)
    readonly property real zoneStart: spanStart - growStart
    readonly property real zoneLength: spanEnd + growEnd - zoneStart
    readonly property var path: PopupOutline.dockedPath({
        barPosition: barPosition,
        length: zoneLength,
        depth: thickness,
        radius: theme.radius,
        joinRadius: joinRadius,
        keepStart: keepStart,
        keepEnd: keepEnd
    })
    readonly property var borderRuns: border ? PopupOutline.dockedBorder({
        barPosition: barPosition,
        length: zoneLength,
        depth: thickness,
        radius: theme.radius,
        joinRadius: joinRadius,
        keepStart: keepStart,
        keepEnd: keepEnd,
        gap: popup ? { start: popup.start - zoneStart, end: popup.end - zoneStart } : null
    }) : []

    x: sideBar ? 0 : zoneStart
    y: sideBar ? zoneStart : 0
    width: sideBar ? thickness : zoneLength
    height: sideBar ? zoneLength : thickness

    Behavior on growStart {
        enabled: root.growthAnimated

        NumberAnimation {
            duration: root.motion.medium
            easing.type: root.motion.easing
        }
    }

    Behavior on growEnd {
        enabled: root.growthAnimated

        NumberAnimation {
            duration: root.motion.medium
            easing.type: root.motion.easing
        }
    }

    onPathChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onBorderRunsChanged: requestPaint()
    onBorderColorChanged: requestPaint()

    Config.Theme {
        id: theme
    }

    onPaint: {
        const context = getContext("2d");

        function trace(run) {
            context.moveTo(run.start.x, run.start.y);
            for (const segment of run.segments) {
                if (segment.controlX === undefined)
                    context.lineTo(segment.x, segment.y);
                else
                    context.quadraticCurveTo(segment.controlX, segment.controlY, segment.x, segment.y);
            }
        }

        context.reset();
        context.fillStyle = fillColor;
        context.beginPath();
        trace(path);
        context.closePath();
        context.fill();

        if (borderRuns.length === 0)
            return;

        context.strokeStyle = borderColor;
        context.lineWidth = 1;
        context.beginPath();
        for (const run of borderRuns)
            trace(run);
        context.stroke();
    }
}
