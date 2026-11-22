import QtQuick
import QtQuick.Shapes

// A ring of the time left in a pomodoro's phase: a faint full track and, over
// it, an arc from the top running clockwise for `fraction` of the way round
// (PomodoroRing.fraction), in the phase's colour (PomodoroRing.phaseColor).
// Drawn on a capsule's pomodoro view and, tiny, on its live element at rest.
Item {
    id: root

    // How much of the ring is drawn, 0 to 1.
    property real fraction: 1
    property color color: "white"
    property color trackColor: Qt.rgba(color.r, color.g, color.b, 0.2)
    property real thickness: 3
    property int size: 16

    readonly property real radius: (size - thickness) / 2

    width: size
    height: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.fraction > 0 ? root.color : "transparent"
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: 360 * root.fraction
            }
        }
    }
}
