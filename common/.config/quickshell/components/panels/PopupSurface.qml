import QtQuick
import "../../config" as Config
import "PopupOutline.js" as PopupOutline

// The surface a popup draws on, its contents inset by the padding. Floating,
// it is one flat card with a hairline border and no shadow, opening with a
// fade and a short slide down. Attached, it hangs from the bar's bottom edge
// with no border: square top corners, small curved corners joining it to the
// bar, round bottom corners, unfolding downward with its contents fading in
// after. Any window can host it; hide the window while reveal is 0. It takes
// no appearance, so the host passes in its motion settings.
Rectangle {
    id: surface

    property bool open: false
    // Appearance.motion (durations and easing), as the host has it.
    required property var motion
    // Hangs from the bar instead of floating below it.
    property bool attached: false
    // The host may paint a floating surface in its own colors.
    property color fillColor: theme.surface
    property color borderColor: theme.border
    // The bar's opacity, 0 to 100 as the bar profile keeps it. An attached
    // surface is painted in the bar's own color and opacity, so it looks like
    // part of the bar.
    property real barOpacity: 100
    readonly property color attachedColor: Qt.rgba(theme.background.r, theme.background.g,
        theme.background.b, barOpacity / 100)
    // How far the curved corners joining an attached surface to the bar reach
    // out beside it.
    property real joinRadius: 6
    // How far the contents are inset from the border.
    property real padding: 12
    // 0 while closed, 1 once open; animates in between.
    property real reveal: open ? 1 : 0
    readonly property int revealDuration: attached ? motion.medium : motion.short
    // How far above its resting place a floating surface starts sliding down from.
    readonly property real revealOffset: 8
    // How much of an attached surface has unfolded, from its top edge down.
    readonly property real unfoldedHeight: attached ? implicitHeight * reveal : height
    // Where in the reveal an attached surface's contents start fading in.
    readonly property real contentsDelay: 0.4
    default property alias contents: content.data

    implicitHeight: content.height + padding * 2
    color: attached ? "transparent" : fillColor
    border.color: borderColor
    border.width: attached ? 0 : 1
    radius: theme.radius
    opacity: attached ? 1 : reveal
    transform: Translate { y: surface.attached ? 0 : -surface.revealOffset * (1 - surface.reveal) }

    Behavior on reveal {
        NumberAnimation {
            duration: surface.revealDuration
            easing.type: surface.motion.easing
        }
    }

    Config.Theme {
        id: theme
    }

    Canvas {
        id: outline

        x: -surface.joinRadius
        width: surface.width + surface.joinRadius * 2
        height: Math.ceil(surface.unfoldedHeight)
        visible: surface.attached

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()

        Connections {
            target: surface

            function onAttachedColorChanged() {
                outline.requestPaint();
            }

            function onRadiusChanged() {
                outline.requestPaint();
            }

            function onUnfoldedHeightChanged() {
                outline.requestPaint();
            }
        }

        onPaint: {
            const context = getContext("2d");
            const left = surface.joinRadius;
            const right = left + surface.width;
            const bottom = surface.unfoldedHeight;
            const corners = PopupOutline.attachedCorners({
                width: surface.width,
                height: bottom,
                radius: surface.radius,
                joinRadius: surface.joinRadius
            });
            const join = corners.join;
            const round = corners.bottom;

            context.reset();
            if (!surface.attached || bottom <= 0)
                return;

            context.fillStyle = surface.attachedColor;
            context.beginPath();
            context.moveTo(left - join, 0);
            context.lineTo(right + join, 0);
            context.quadraticCurveTo(right, 0, right, join);
            context.lineTo(right, bottom - round);
            context.quadraticCurveTo(right, bottom, right - round, bottom);
            context.lineTo(left + round, bottom);
            context.quadraticCurveTo(left, bottom, left, bottom - round);
            context.lineTo(left, join);
            context.quadraticCurveTo(left, 0, left - join, 0);
            context.closePath();
            context.fill();
        }
    }

    // Shows only what has unfolded of an attached surface.
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: surface.unfoldedHeight
        clip: surface.attached

        Item {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: surface.padding
            height: childrenRect.height
            opacity: surface.attached
                ? Math.max(0, (surface.reveal - surface.contentsDelay) / (1 - surface.contentsDelay)) : 1
        }
    }
}
