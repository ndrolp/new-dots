import QtQuick
import "../../config" as Config
import "." as Panels

// The monitors to scale, to drag into place. Dropping one only says where: whoever owns the setup
// snaps it and hands the result back, and a monitor whose drop came to nothing goes back to its place.
Rectangle {
    id: canvas

    required property var appearance
    // Each monitor is { id, number, label, x, y, width, height }, in logical pixels.
    property var monitors: []
    property string selectedId: ""
    signal selected(string id)
    signal dropped(string id, real x, real y)

    readonly property real margin: 16
    readonly property real originX: monitors.length > 0 ? Math.min(...monitors.map(item => item.x)) : 0
    readonly property real originY: monitors.length > 0 ? Math.min(...monitors.map(item => item.y)) : 0
    readonly property real spanX: monitors.length > 0
        ? Math.max(...monitors.map(item => item.x + item.width)) - originX : 1
    readonly property real spanY: monitors.length > 0
        ? Math.max(...monitors.map(item => item.y + item.height)) - originY : 1
    // On-screen pixels per logical pixel.
    readonly property real drawScale: Math.min((width - 2 * margin) / spanX, (height - 2 * margin) / spanY)
    readonly property real offsetX: (width - spanX * drawScale) / 2
    readonly property real offsetY: (height - spanY * drawScale) / 2

    height: 240
    radius: appearance.radius
    color: "transparent"
    border.color: theme.border
    border.width: 1

    Config.Theme {
        id: theme
    }

    Repeater {
        model: canvas.monitors

        delegate: Rectangle {
            id: monitor

            required property var modelData
            readonly property string monitorId: modelData.id
            readonly property bool isSelected: canvas.selectedId === modelData.id
            property real dragX: 0
            property real dragY: 0
            property bool dragging: false

            x: dragging ? dragX : canvas.offsetX + (modelData.x - canvas.originX) * canvas.drawScale
            y: dragging ? dragY : canvas.offsetY + (modelData.y - canvas.originY) * canvas.drawScale
            z: dragging ? 1 : 0
            width: modelData.width * canvas.drawScale
            height: modelData.height * canvas.drawScale
            radius: 4
            color: isSelected ? theme.surfaceHover : theme.surface
            border.color: isSelected ? theme.accent : theme.border
            border.width: isSelected ? 2 : 1

            Column {
                anchors.centerIn: parent
                width: parent.width - 12

                Panels.ShellText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: monitor.modelData.number
                    color: theme.text
                    font.pixelSize: canvas.appearance.textSize + 8
                }

                Panels.ShellText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: monitor.modelData.label
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: canvas.appearance.textSize - 2
                }
            }

            MouseArea {
                // A press that wanders less than this is still a tap.
                readonly property real dragDistance: 4
                property real pressX: 0
                property real pressY: 0

                anchors.fill: parent
                // The section scrolls, and would take a drag that drifts up or down.
                preventStealing: true
                cursorShape: monitor.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: mouse => {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    monitor.dragX = monitor.x;
                    monitor.dragY = monitor.y;
                }

                onPositionChanged: mouse => {
                    const dx = mouse.x - pressX;
                    const dy = mouse.y - pressY;
                    if (!monitor.dragging && Math.hypot(dx, dy) < dragDistance)
                        return;
                    monitor.dragging = true;
                    monitor.dragX += dx;
                    monitor.dragY += dy;
                }

                onCanceled: monitor.dragging = false

                onReleased: {
                    if (!monitor.dragging) {
                        canvas.selected(monitor.monitorId);
                        return;
                    }
                    const logicalX = canvas.originX + (monitor.dragX - canvas.offsetX) / canvas.drawScale;
                    const logicalY = canvas.originY + (monitor.dragY - canvas.offsetY) / canvas.drawScale;
                    monitor.dragging = false;
                    canvas.selected(monitor.monitorId);
                    canvas.dropped(monitor.monitorId, Math.round(logicalX), Math.round(logicalY));
                }
            }
        }
    }
}
