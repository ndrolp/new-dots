import QtQuick
import "../../config" as Config

Canvas {
    id: root

    required property var appearance
    property color fillColor: "#313244"
    property int slant: 15
    property bool keepLeftEdge: false
    property bool keepRightEdge: false
    property bool slantBothSides: false

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()

    Config.Theme {
        id: theme
    }

    onPaint: {
        const context = getContext("2d");
        const radius = Math.min(height / 2, Math.max(appearance.radius, 12));

        context.reset();
        context.fillStyle = fillColor;
        context.beginPath();
        if (keepLeftEdge) {
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.bezierCurveTo(
                width - slant * 0.7, 0,
                width - slant * 0.1, height,
                width - slant, height
            );
            context.lineTo(0, height);
        } else if (keepRightEdge) {
            context.moveTo(0, 0);
            context.bezierCurveTo(
                slant * 0.7, 0,
                slant * 0.1, height,
                slant, height
            );
            context.lineTo(width, height);
            context.lineTo(width, 0);
        } else if (slantBothSides) {
            context.moveTo(0, 0);
            context.bezierCurveTo(
                slant * 0.7, 0,
                slant * 0.1, height,
                slant, height
            );
            context.lineTo(width - slant, height);
            context.bezierCurveTo(
                width - slant * 0.1, height,
                width - slant * 0.7, 0,
                width, 0
            );
            context.lineTo(width, 0);
        } else {
            context.moveTo(radius, 0);
            context.lineTo(width - radius, 0);
            context.quadraticCurveTo(width, 0, width, radius);
            context.lineTo(width, height - radius);
            context.quadraticCurveTo(width, height, width - radius, height);
            context.lineTo(radius, height);
            context.quadraticCurveTo(0, height, 0, height - radius);
            context.lineTo(0, radius);
            context.quadraticCurveTo(0, 0, radius, 0);
        }

        context.closePath();
        context.fill();
    }
}
