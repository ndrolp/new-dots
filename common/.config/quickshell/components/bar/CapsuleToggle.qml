import QtQuick

// Whether SUPER+I holds the capsule expanded: from one press until the next,
// or until the pointer leaves the capsule.
Item {
    id: root

    // Whether the pointer is over the capsule now.
    property bool hovering: false
    // Whether the keybind holds the capsule expanded.
    readonly property alias toggled: state.toggled

    // Expands the capsule, or collapses it if the keybind expanded it.
    function toggle() {
        state.toggled = !state.toggled;
    }

    onHoveringChanged: {
        if (!hovering)
            state.toggled = false;
    }

    QtObject {
        id: state

        property bool toggled: false
    }
}
