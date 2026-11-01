import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// The shell's one bridge to the menus apps export over D-Bus (the app's own
// File, Edit, View...), run by app-menu-bridge.py while something shows the
// app menu (see setUsing): an enabled app menu bar element or the app menu
// popover. It follows Hyprland's focused window and
// hands over that window's menus raw as `exported`, for `exportedPid`;
// AppMenuModel.exportedMenus makes menus of them. With no registrar, an app
// that exports nothing, or no python3-gi, `exported` stays null and the app
// menu shows the shell's menus only; the reason goes to the Quickshell log
// once.
QtObject {
    id: root

    // What the focused app exports, as AppMenuModel.exportedMenus takes it,
    // or null; it belongs to the window whose pid is `exportedPid`.
    property var exported: null
    property int exportedPid: -1
    // What shows the app menu right now (bar elements, the popover).
    property var users: []
    readonly property bool needed: users.length > 0

    readonly property var focus: {
        const toplevel = Hyprland.activeToplevel;
        const ipc = toplevel ? toplevel.lastIpcObject || {} : {};
        return toplevel && ipc.pid ? { pid: ipc.pid, title: toplevel.title || "", xwayland: ipc.xwayland === true }
            : null;
    }

    // Called by whatever shows the app menu as it starts or stops.
    function setUsing(user, using) {
        const others = users.filter(entry => entry !== user);
        users = using ? others.concat([user]) : others;
    }

    // What the focused app exports, when the window with `pid` is focused.
    function exportedFor(pid) {
        return pid === exportedPid ? exported : null;
    }

    // Runs a dbusMenu or gtkAction action (see AppMenuModel) in the app.
    function activate(action) {
        send({ activate: action });
    }

    function send(message) {
        if (bridge.running)
            bridge.write(JSON.stringify(message) + "\n");
    }

    function sendFocus() {
        send({ focus: focus });
    }

    onFocusChanged: sendFocus()

    // A window's pid is only read on a refresh, which a newly focused one
    // may not have had yet.
    property Connections focusEvents: Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.needed && event.name === "activewindowv2" && root.focus === null)
                Hyprland.refreshToplevels();
        }
    }
    onNeededChanged: {
        if (!needed) {
            exported = null;
            exportedPid = -1;
        }
    }

    property var process: Process {
        id: bridge

        running: root.needed
        command: ["python3", Quickshell.shellDir + "/services/app-menu-bridge.py"]
        stdinEnabled: true

        onStarted: root.sendFocus()

        stdout: SplitParser {
            onRead: data => {
                let message;
                try {
                    message = JSON.parse(data);
                } catch (error) {
                    return;
                }
                if (message.log) {
                    console.log(message.log);
                } else if (message.pid !== undefined) {
                    root.exportedPid = message.pid;
                    root.exported = message.exported;
                }
            }
        }

        onExited: exitCode => {
            root.exported = null;
            root.exportedPid = -1;
            if (exitCode !== 0)
                console.log("app menu: app-menu-bridge.py exited with " + exitCode
                    + "; showing the shell menus only");
        }
    }
}
