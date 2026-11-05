import QtQuick
import "../BarPosition.js" as BarPosition

// Animates x or width on a top or bottom bar and y or height on a side bar, what
// runs along the bar: across it, things follow the bar at once.
Behavior {
    id: root

    required property var appearance
    property int duration: appearance.motion.medium

    enabled: ["x", "width"].includes(targetProperty.name) !== BarPosition.sideBar(appearance.barPosition)

    NumberAnimation {
        duration: root.duration
        easing.type: root.appearance.motion.easing
    }
}
