import QtQuick
import QtQuick.Shapes
import "../../config" as Config
import "PopupOutline.js" as PopupOutline
import "PopupPlacement.js" as PopupPlacement

// The surface a popup draws on, its contents inset by the padding. Floating,
// it is one flat card with a hairline border and no shadow, opening with a
// fade and a short slide away from the bar. Attached, it hangs from the bar with
// no border: square corners against it, small curved corners joining it to the
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
    readonly property real unfolded: (PopupPlacement.vertical(barPosition) ? width : height)
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

            PathLine { x: outline.path.segments[0].x; y: outline.path.segments[0].y }
            PathQuad {
                x: outline.path.segments[1].x; y: outline.path.segments[1].y
                controlX: outline.path.segments[1].controlX; controlY: outline.path.segments[1].controlY
            }
            PathLine { x: outline.path.segments[2].x; y: outline.path.segments[2].y }
            PathQuad {
                x: outline.path.segments[3].x; y: outline.path.segments[3].y
                controlX: outline.path.segments[3].controlX; controlY: outline.path.segments[3].controlY
            }
            PathLine { x: outline.path.segments[4].x; y: outline.path.segments[4].y }
            PathQuad {
                x: outline.path.segments[5].x; y: outline.path.segments[5].y
                controlX: outline.path.segments[5].controlX; controlY: outline.path.segments[5].controlY
            }
            PathLine { x: outline.path.segments[6].x; y: outline.path.segments[6].y }
            PathQuad {
                x: outline.path.segments[7].x; y: outline.path.segments[7].y
                controlX: outline.path.segments[7].controlX; controlY: outline.path.segments[7].controlY
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
