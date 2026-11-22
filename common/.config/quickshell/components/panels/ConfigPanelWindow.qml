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
    property var monitorSetups
    property bool open: false
    property var targetWindow
    property real reveal: open ? 1 : 0

    // What its panel shows (ConfigPanel.view).
    readonly property var view: configPanel.view

    signal closeRequested()

    function openSection(section) {
        configPanel.openSection(section);
    }

    function restoreView(view) {
        configPanel.restoreView(view);
    }

    // Opened, the panel takes the keyboard, so Escape closes it.
    onOpenChanged: {
        if (open)
            configPanel.forceActiveFocus();
    }

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
            easing.type: root.appearance.motion.easing
        }
    }

    mask: Region {
        item: configPanel
    }

    ConfigPanel {
        id: configPanel

        anchors.centerIn: parent
        focus: true
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
        monitorSetups: root.monitorSetups

        onCloseRequested: root.closeRequested()
    }
}
