import QtQuick
import QtQuick.Shapes
import "../../config" as Config
import "../BarPosition.js" as BarPosition
import "PopupOutline.js" as PopupOutline
import "PopupPlacement.js" as PopupPlacement

// The surface a popup draws on, its contents inset by the padding. Floating,
// it is one flat card with a hairline border and no shadow, opening with a
// fade and a short slide away from the bar. Attached, it hangs from the bar with
// no border unless the bar border is on: square corners against it, small curved corners joining it to the
// bar, round corners away from it, unfolding away from the bar with its contents
// fading in after. Any window can host it; hide the window while reveal is 0. It
// takes no appearance, so the host passes in its motion settings. Closing, it
// ignores input while the animation runs.
Rectangle {
    id: surface

    property bool open: false
    // Appearance.motion (durations and easing), as the host has it.
    required property var motion
    // The screen edge the bar sits on; the surface opens away from it.
    property string barPosition: "top"
    // Hangs from the bar instead of floating clear of it.
    property bool attached: false
    // The host may paint a floating surface in its own colors.
    property color fillColor: theme.surface
    property color borderColor: theme.border
    // The bar border is on: an attached surface carries the bar's hairline on
    // round itself, leaving out the side against the bar.
    property bool barBorder: false
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
    // How far towards the bar a floating surface starts sliding from.
    readonly property real revealOffset: 8
    // How far an attached surface has unfolded, measured from the bar.
    readonly property real unfolded: (BarPosition.sideBar(barPosition) ? width : height)
        * (attached ? reveal : 1)
    // The part of the surface that has unfolded.
    readonly property var unfoldedArea: PopupOutline.unfoldedArea({
        barPosition: barPosition,
        width: width,
        height: height,
        unfolded: unfolded
    })
    // Where in the reveal an attached surface's contents start fading in.
    readonly property real contentsDelay: 0.4
    default property alias contents: content.data

    // Off while closing, so a fast second click reaches nothing.
    enabled: open
    implicitHeight: content.height + padding * 2
    color: attached ? "transparent" : fillColor
    border.color: borderColor
    border.width: attached ? 0 : 1
    radius: theme.radius
    opacity: attached ? 1 : reveal
    transform: Translate {
        readonly property var offset: PopupPlacement.towardsBar(surface.barPosition,
            surface.attached ? 0 : surface.revealOffset * (1 - surface.reveal))

        x: offset.x
        y: offset.y
    }

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

        readonly property var path: PopupOutline.attachedPath({
            barPosition: surface.barPosition,
            width: surface.width,
            height: surface.height,
            unfolded: surface.unfolded,
            radius: surface.radius,
            joinRadius: surface.joinRadius
        })

        x: path.x
        y: path.y
        width: path.width
        height: path.height
        visible: surface.attached && surface.unfolded > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: surface.attachedColor
            strokeWidth: -1
            startX: outline.path.start.x
            startY: outline.path.start.y

            PathLine { x: outline.path.parts.barSide.x; y: outline.path.parts.barSide.y }
            PathQuad {
                x: outline.path.parts.endJoin.x; y: outline.path.parts.endJoin.y
                controlX: outline.path.parts.endJoin.controlX; controlY: outline.path.parts.endJoin.controlY
            }
            PathLine { x: outline.path.parts.endSide.x; y: outline.path.parts.endSide.y }
            PathQuad {
                x: outline.path.parts.endCorner.x; y: outline.path.parts.endCorner.y
                controlX: outline.path.parts.endCorner.controlX; controlY: outline.path.parts.endCorner.controlY
            }
            PathLine { x: outline.path.parts.farSide.x; y: outline.path.parts.farSide.y }
            PathQuad {
                x: outline.path.parts.startCorner.x; y: outline.path.parts.startCorner.y
                controlX: outline.path.parts.startCorner.controlX; controlY: outline.path.parts.startCorner.controlY
            }
            PathLine { x: outline.path.parts.startSide.x; y: outline.path.parts.startSide.y }
            PathQuad {
                x: outline.path.parts.startJoin.x; y: outline.path.parts.startJoin.y
                controlX: outline.path.parts.startJoin.controlX; controlY: outline.path.parts.startJoin.controlY
            }
        }
    }

    // The bar border round an attached surface.
    Shape {
        id: attachedBorder

        readonly property var path: PopupOutline.attachedBorder({
            barPosition: surface.barPosition,
            width: surface.width,
            height: surface.height,
            unfolded: surface.unfolded,
            radius: surface.radius,
            joinRadius: surface.joinRadius
        })

        x: path.x
        y: path.y
        width: path.width
        height: path.height
        visible: surface.attached && surface.barBorder && surface.unfolded > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: surface.borderColor
            strokeWidth: 1
            capStyle: ShapePath.FlatCap
            startX: attachedBorder.path.start.x
            startY: attachedBorder.path.start.y

            PathQuad {
                x: attachedBorder.path.parts.endJoin.x; y: attachedBorder.path.parts.endJoin.y
                controlX: attachedBorder.path.parts.endJoin.controlX; controlY: attachedBorder.path.parts.endJoin.controlY
            }
            PathLine { x: attachedBorder.path.parts.endSide.x; y: attachedBorder.path.parts.endSide.y }
            PathQuad {
                x: attachedBorder.path.parts.endCorner.x; y: attachedBorder.path.parts.endCorner.y
                controlX: attachedBorder.path.parts.endCorner.controlX; controlY: attachedBorder.path.parts.endCorner.controlY
            }
            PathLine { x: attachedBorder.path.parts.farSide.x; y: attachedBorder.path.parts.farSide.y }
            PathQuad {
                x: attachedBorder.path.parts.startCorner.x; y: attachedBorder.path.parts.startCorner.y
                controlX: attachedBorder.path.parts.startCorner.controlX; controlY: attachedBorder.path.parts.startCorner.controlY
            }
            PathLine { x: attachedBorder.path.parts.startSide.x; y: attachedBorder.path.parts.startSide.y }
            PathQuad {
                x: attachedBorder.path.parts.startJoin.x; y: attachedBorder.path.parts.startJoin.y
                controlX: attachedBorder.path.parts.startJoin.controlX; controlY: attachedBorder.path.parts.startJoin.controlY
            }
        }
    }

    // Shows only what has unfolded of an attached surface.
    Item {
        id: unfoldedPart

        x: surface.unfoldedArea.x
        y: surface.unfoldedArea.y
        width: surface.unfoldedArea.width
        height: surface.unfoldedArea.height
        clip: surface.attached

        // Stays where it rests in the surface, whatever part has unfolded.
        Item {
            id: content

            x: surface.padding - unfoldedPart.x
            y: surface.padding - unfoldedPart.y
            width: surface.width - surface.padding * 2
            height: childrenRect.height
            opacity: surface.attached
                ? Math.max(0, (surface.reveal - surface.contentsDelay) / (1 - surface.contentsDelay)) : 1
        }
    }
}
