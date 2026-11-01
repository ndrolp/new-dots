import QtQuick
import QtQuick.Shapes
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

    // The attached outline, drawn as a Shape so it reshapes on the GPU each
    // frame it unfolds or resizes instead of repainting a raster canvas.
    Shape {
        id: outline

        readonly property real edgeLeft: surface.joinRadius
        readonly property real edgeRight: edgeLeft + surface.width
        readonly property real edgeBottom: Math.max(0, surface.unfoldedHeight)
        readonly property var corners: PopupOutline.attachedCorners({
            width: surface.width,
            height: edgeBottom,
            radius: surface.radius,
            joinRadius: surface.joinRadius
        })

        x: -surface.joinRadius
        width: surface.width + surface.joinRadius * 2
        height: Math.ceil(edgeBottom)
        visible: surface.attached && edgeBottom > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: surface.attachedColor
            strokeWidth: -1
            startX: outline.edgeLeft - outline.corners.join
            startY: 0

            PathLine { x: outline.edgeRight + outline.corners.join; y: 0 }
            PathQuad {
                x: outline.edgeRight; y: outline.corners.join
                controlX: outline.edgeRight; controlY: 0
            }
            PathLine { x: outline.edgeRight; y: outline.edgeBottom - outline.corners.bottom }
            PathQuad {
                x: outline.edgeRight - outline.corners.bottom; y: outline.edgeBottom
                controlX: outline.edgeRight; controlY: outline.edgeBottom
            }
            PathLine { x: outline.edgeLeft + outline.corners.bottom; y: outline.edgeBottom }
            PathQuad {
                x: outline.edgeLeft; y: outline.edgeBottom - outline.corners.bottom
                controlX: outline.edgeLeft; controlY: outline.edgeBottom
            }
            PathLine { x: outline.edgeLeft; y: outline.corners.join }
            PathQuad {
                x: outline.edgeLeft - outline.corners.join; y: 0
                controlX: outline.edgeLeft; controlY: 0
            }
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
