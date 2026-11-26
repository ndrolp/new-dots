import QtQuick
import QtQuick.Shapes

// A glance card's ring (a change's glance card in CapsuleChangeView.qml, the
// capsule glance's cards in CapsuleGlanceView.qml): a track, and an arc from
// the top round to the level.
Shape {
    id: ring

    // How full the ring is, 0 to 1.
    property real level: 0
    property real stroke: 3
    property color trackColor: "transparent"
    property color levelColor: "white"

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: ring.trackColor
        strokeWidth: ring.stroke

        PathAngleArc {
            centerX: ring.width / 2
            centerY: ring.height / 2
            radiusX: (ring.width - ring.stroke) / 2
            radiusY: radiusX
            startAngle: 0
            sweepAngle: 360
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: ring.levelColor
        strokeWidth: ring.stroke
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: ring.width / 2
            centerY: ring.height / 2
            radiusX: (ring.width - ring.stroke) / 2
            radiusY: radiusX
            startAngle: -90
            sweepAngle: 360 * Math.max(0, Math.min(1, ring.level))
        }
    }
}
