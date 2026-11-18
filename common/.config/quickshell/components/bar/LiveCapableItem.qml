import QtQuick

// Holds the item of a bar element that can be live (see GLOSSARY.md), its
// only child, at the bar element's place, as large as that item. Beside a
// capsule's workspace pills, as a live element, it fades in and out, and
// stays visible while it fades out, and slides with the pills; anywhere
// else it shows and moves at once.
Item {
    id: root

    required property var appearance
    // The bar element it holds, by id.
    required property string element
    // Where the bar draws its elements (BarElementItems): whether one is
    // shown (`itemVisible`) and live (`live`), its `sizes` and its place
    // (`elementX`, `elementY`), each taking the element's id.
    required property var items

    // Whether it is shown. While it fades out it is no longer shown, but
    // still visible and it keeps its room beside the pills, so they and the
    // capsule close up only once it is gone.
    readonly property bool shown: items.itemVisible(element)
    readonly property bool takesRoom: shown || opacity > 0
    readonly property bool live: items.live(element)
    // The sizes its item is drawn at (LiveElements.elementSizes).
    readonly property var sizes: items.sizes(element)
    readonly property Item content: children.length > 0 ? children[0] : null

    visible: takesRoom
    opacity: shown ? 1 : 0
    x: items.elementX(element)
    y: items.elementY(element)
    width: content ? content.width : 0
    height: content ? content.height : 0

    Behavior on opacity {
        enabled: root.live
        NumberAnimation { duration: root.appearance.motion.medium; easing.type: root.appearance.motion.easing }
    }

    AlongBarBehavior on x { appearance: root.appearance; enabled: root.live }
}
