import Quickshell
import Quickshell.Wayland
import QtQuick

// Keep-awake: while on, the session doesn't go idle. The shell owns the one
// instance, so the control center tile, the keep-awake bar element and its
// popup share it, and it isn't saved, so every shell start begins with it off.
Scope {
    id: root

    property bool on: false

    function toggle() {
        on = !on;
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
