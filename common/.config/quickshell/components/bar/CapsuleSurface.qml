import QtQuick

// The capsule itself: a round-ended shape in the profile's background colour
// and opacity, behind its row of bar elements, with the bar border around it
// when that setting is on. It slides and stretches along the bar as the row
// changes.
Item {
    id: root

    // Where it sits and its size, as Capsule.surface gives it.
    required property var place
    required property color fillColor
    // Whether the bar border runs around it.
    property bool border: false
    property color borderColor: "transparent"
    // The bar's appearance, for its Bar position and motion.
    required property var appearance
    readonly property real radius: place.radius

    x: place.x
    y: place.y
    width: place.width
    height: place.height

    AlongBarBehavior on x { appearance: root.appearance }
    AlongBarBehavior on width { appearance: root.appearance }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
        border.width: root.border ? 1 : 0
        border.color: root.border ? root.borderColor : "transparent"
    }
}
