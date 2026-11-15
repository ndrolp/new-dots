import QtQuick

// The capsule itself: a round-ended shape in the profile's background colour
// and opacity, behind its row of bar elements, with the bar border around it
// when that setting is on. It slides and stretches along the bar as the row
// changes, and grows and shrinks across it as a popup inside opens, closes or
// resizes.
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
    // Whether a popup inside is resizing itself in its own animation, which
    // the capsule then follows frame by frame instead of animating again.
    property bool following: false
    readonly property real radius: place.radius

    x: place.x
    y: place.y
    width: place.width
    height: place.height

    AlongBarBehavior on x { appearance: root.appearance }
    AlongBarBehavior on width { appearance: root.appearance }

    Behavior on y {
        enabled: !root.following

        NumberAnimation {
            duration: root.appearance.motion.medium
            easing.type: root.appearance.motion.easing
        }
    }

    Behavior on height {
        enabled: !root.following

        NumberAnimation {
            duration: root.appearance.motion.medium
            easing.type: root.appearance.motion.easing
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fillColor
        border.width: root.border ? 1 : 0
        border.color: root.border ? root.borderColor : "transparent"
    }
}
