import QtQuick

// The change a capsule shows instead of the OSD (volume, brightness, Caps
// Lock, audio output, bar profile or keep-awake), and for how long: about
// 1.5 s from the latest one, so holding a volume key keeps it open. This is
// timing, not animation: Reduce motion leaves it as it is.
Item {
    id: root

    // How long a change shows, in ms.
    property int duration: 1500
    // Whether a change shows now.
    readonly property alias shown: state.shown
    // The latest change, as OsdChange.js describes it, or null before any.
    readonly property alias change: state.change

    // Shows `change`, replacing the one showing, for another `duration`.
    function show(change) {
        state.change = change;
        state.shown = true;
        hideTimer.restart();
    }

    QtObject {
        id: state

        property bool shown: false
        property var change: null
    }

    Timer {
        id: hideTimer

        interval: root.duration
        onTriggered: state.shown = false
    }
}
