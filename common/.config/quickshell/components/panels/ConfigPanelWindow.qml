import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    required property var bookmarks
    required property var plugins
    property var cava
    property bool open: false
    property var targetWindow
    property real reveal: open ? 1 : 0

    signal closeRequested()

    visible: reveal > 0 && targetWindow !== null
    screen: targetWindow ? targetWindow.screen : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.namespace: "ndro-shell-settings"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Behavior on reveal {
        NumberAnimation {
            duration: root.appearance.motion.long
            easing.type: root.appearance.motionEasing
        }
    }

    mask: Region {
        item: configPanel
    }

    ConfigPanel {
        id: configPanel

        anchors.centerIn: parent
        opacity: root.reveal
        transform: Translate {
            y: -16 * (1 - root.reveal)
        }
        appearance: root.appearance
        monitors: root.monitors
        wallpapers: root.wallpapers
        bookmarks: root.bookmarks
        plugins: root.plugins
        cava: root.cava

        onCloseRequested: root.closeRequested()
    }
}
