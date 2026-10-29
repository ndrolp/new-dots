import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "KeepAwakeState.js" as KeepAwakeState

// Keep-awake: while on, the session doesn't go idle. The shell owns the one
// instance, so the control center tile, the keep-awake bar element and its
// popup share it, and it isn't saved, so every shell start begins with it off
// and "until turned off" selected. Turning it on uses the selected duration;
// when a timed one runs out it turns off and sends a notification. That is
// decided in KeepAwakeState.js; this only carries it out.
Scope {
    id: root

    readonly property bool on: internal.state.on
    // The selected duration in minutes, or KeepAwakeState.untilTurnedOff.
    readonly property int duration: internal.state.duration
    // Whether a countdown is running, and the whole seconds left on it.
    readonly property bool timed: KeepAwakeState.timed(internal.state)
    readonly property int secondsLeft: internal.secondsLeft

    function toggle() {
        setState(KeepAwakeState.toggled(internal.state, Date.now()));
    }

    function chooseDuration(minutes) {
        setState(KeepAwakeState.durationChosen(internal.state, minutes, Date.now()));
    }

    // Takes on `next` (from KeepAwakeState.js) and reads the time left on it.
    function setState(next) {
        internal.state = next;
        internal.secondsLeft = KeepAwakeState.secondsLeft(next, Date.now());
    }

    QtObject {
        id: internal

        property var state: KeepAwakeState.off
        property int secondsLeft: 0
    }

    // Counts down while timed. The time left comes from the clock, not from
    // counting ticks, so a late tick doesn't stretch the countdown.
    Timer {
        interval: 1000
        repeat: true
        running: root.timed
        onTriggered: {
            const tick = KeepAwakeState.ticked(internal.state, Date.now());
            root.setState(tick.state);
            if (tick.ended)
                endedNotification.exec(KeepAwakeState.endedNotificationCommand);
        }
    }

    Process {
        id: endedNotification
    }

    // An idle inhibitor counts only while its surface is shown, so it gets a
    // window of its own: one transparent, click-through pixel that exists
    // only while keep-awake is on.
    LazyLoader {
        active: root.on

        PanelWindow {
            id: inhibitorWindow

            anchors.top: true
            anchors.left: true
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "ndro-shell-keep-awake"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            IdleInhibitor {
                window: inhibitorWindow
                enabled: true
            }
        }
    }
}
