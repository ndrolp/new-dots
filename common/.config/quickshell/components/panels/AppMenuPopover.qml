import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import ".." as Components
import "AppMenuPopover.js" as Popover

// The app menu popover: the focused app's menus as one list at the mouse
// cursor, on the focused monitor (AppMenuPopover.js says what the list holds
// and where it opens). It isn't a Popup: it belongs to no bar element. It
// closes when it loses focus, on Escape, or once an item is chosen; items
// work as in the app menu's Popup.
Scope {
    id: root

    required property var appearance
    property bool open: false
    // The list as it was when it opened, so it holds still while open.
    property var shownItems: []
    property var cursor: null
    // Open once the cursor is known and there is something to show.
    readonly property bool shown: open && cursor !== null && shownItems.length > 0

    signal closeRequested()

    onOpenChanged: {
        cursor = null;
        if (!open)
            return;
        shownItems = Popover.items(source.menus);
        if (shownItems.length === 0) {
            closeRequested();
            return;
        }
        cursorQuery.running = true;
    }

    Components.AppMenuSource {
        id: source
    }

    Process {
        id: cursorQuery

        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.cursor = JSON.parse(text);
                } catch (error) {
                    root.closeRequested();
                }
            }
        }
    }

    PanelWindow {
        id: popover

        readonly property var focusedScreen: {
            const monitor = Hyprland.focusedMonitor;
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++) {
                if (monitor && screens[i].name === monitor.name)
                    return screens[i];
            }
            return screens[0];
        }
        // Room for the surface's slide in.
        readonly property real inset: surface.revealOffset
        readonly property var place: Popover.position({
            cursor: root.cursor || { x: 0, y: 0 },
            screen: focusedScreen,
            width: implicitWidth,
            height: implicitHeight,
            margin: 8
        })

        screen: focusedScreen
        visible: surface.reveal > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-app-menu-popover"
        WlrLayershell.layer: WlrLayer.Overlay
        implicitWidth: 260
        implicitHeight: surface.implicitHeight + inset

        anchors {
            top: true
            left: true
        }
        margins {
            left: place.x
            top: place.y
        }

        HyprlandFocusGrab {
            windows: [popover]
            active: root.shown && popover.visible
            onCleared: root.closeRequested()
        }

        PopupSurface {
            id: surface

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: popover.inset
            height: implicitHeight
            open: root.shown
            enabled: root.shown
            radius: root.appearance.radius
            motion: root.appearance.motion
            padding: 6
            focus: root.shown

            Keys.onEscapePressed: root.closeRequested()

            AppMenuList {
                width: parent.width
                appearance: root.appearance
                items: root.shownItems

                onActionChosen: function(action) {
                    source.run(action);
                    root.closeRequested();
                }
            }
        }
    }
}
