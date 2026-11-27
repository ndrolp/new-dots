import QtQuick
import "CapsulePlacement.js" as CapsulePlacement

// The part of the bar content the pointer hovers: only the capsule, its
// workspace pills and its glance included, though they are drawn past the
// bar content, which is only as deep as its row. Given to BarContent as its
// containmentMask, so its HoverHandler counts the pointer over the glance
// cards as over the capsule; a HoverHandler only counts a point its item
// contains, and without a mask that is only the item's own bounds.
QtObject {
    // The capsule, as CapsulePlacement.withInside grows it round the glance,
    // or null without one, when nothing is hovered.
    property var place: null

    function contains(point: point): bool {
        return CapsulePlacement.contains(place, point);
    }
}
