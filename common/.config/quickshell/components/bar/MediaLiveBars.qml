import QtQuick
import "../panels/MediaCard.js" as MediaCard

// The moving bars of the media live element at rest (MediaCard.liveBars):
// the shared cava's frame while cava works, or else a simple equaliser that
// steps while the player plays and stands still while it is paused.
CavaBars {
    id: root

    // The shared cava (services/Cava.qml).
    required property var cava
    // Whether the player it follows is playing.
    property bool playing: false
    // Whether it is drawn: while it is, it keeps the shared cava running.
    property bool drawing: false
    readonly property var bars: MediaCard.liveBars(playing, cava.failureHint)
    // How often the equaliser steps, in ms.
    readonly property int equaliserInterval: 160
    property int step: 0

    frame: bars.source === "cava" ? cava.heights : MediaCard.equaliserFrame(barCount, step)
    colorName: "green"

    Timer {
        interval: root.equaliserInterval
        repeat: true
        running: root.drawing && root.bars.source === "equaliser" && root.bars.moving
        onTriggered: root.step++
    }

    onDrawingChanged: cava.setDrawing(root, drawing)
    Component.onCompleted: cava.setDrawing(root, drawing)
    Component.onDestruction: cava.setDrawing(root, false)
}
