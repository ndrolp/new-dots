import QtQuick

// How much taller a capsule's bar window is held for a popup inside it: as
// much as the tallest popup has needed so far, from the moment it needs it.
// It never shrinks: Hyprland animates a layer's size change, stretching its
// last picture to the old size meanwhile, so a shrinking window would flash
// a stretched capsule. The room left over is transparent and takes no clicks.
Item {
    id: root

    // How much taller the window must be now, in px.
    property real needed: 0
    // How much taller the window is held, in px.
    readonly property real held: Math.max(needed, state.tallest)

    onNeededChanged: state.tallest = Math.max(state.tallest, needed)

    QtObject {
        id: state

        property real tallest: 0
    }
}
