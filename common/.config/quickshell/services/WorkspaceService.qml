import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "../components/panels/WorkspaceOverview.js" as WorkspaceOverview

QtObject {
    id: root

    // The rules from `hyprctl workspacerules -j`, read once at start and again
    // through refreshWorkspaceRules.
    property var workspaceRules: []

    function monitorDescriptionForScreen(screen) {
        if (screen === null || screen === undefined)
            return "default";

        const monitor = Hyprland.monitorFor(screen);
        return monitor !== null && monitor.description !== "" ? monitor.description : screen.name;
    }

    // The monitor with keyboard focus, named like monitorDescriptionForScreen.
    function focusedMonitorDescription() {
        const monitor = Hyprland.focusedMonitor;
        if (monitor === null)
            return "default";

        return monitor.description !== "" ? monitor.description : monitor.name;
    }

    // The workspaces Hyprland has, as { id, monitor } with the monitor's name.
    function existingWorkspaces() {
        return Hyprland.workspaces.values
            .filter(workspace => workspace.monitor !== null)
            .map(workspace => ({ id: workspace.id, monitor: workspace.monitor.name }));
    }

    // Reads Hyprland's workspace rules into workspaceRules.
    function refreshWorkspaceRules() {
        workspaceRulesReader.running = true;
    }

    function workspacesForScreen(screen, configuredWorkspaces) {
        const monitor = Hyprland.monitorFor(screen);
        const workspaceIds = (configuredWorkspaces || []).filter(id => id >= 1 && id <= 21);
        const workspaces = Hyprland.workspaces.values;

        for (let index = 0; index < workspaces.length; index++) {
            const workspace = workspaces[index];

            if (workspace.id >= 1 && workspace.id <= 21
                    && workspace.active && monitor !== null && workspace.monitor !== null
                    && workspace.monitor.name === monitor.name
                    && workspaceIds.indexOf(workspace.id) === -1) {
                workspaceIds.push(workspace.id);
            }
        }

        const toplevels = Hyprland.toplevels.values;

        for (let index = 0; index < toplevels.length; index++) {
            const workspace = toplevels[index].workspace;

            if (workspace !== null && workspace.id >= 1 && workspace.id <= 21
                    && monitor !== null && workspace.monitor !== null
                    && workspace.monitor.name === monitor.name
                    && workspaceIds.indexOf(workspace.id) === -1) {
                workspaceIds.push(workspace.id);
            }
        }

        workspaceIds.sort((left, right) => left - right);
        return workspaceIds;
    }

    function workspaceFor(id) {
        const workspaces = Hyprland.workspaces.values;

        for (let index = 0; index < workspaces.length; index++) {
            if (workspaces[index].id === id)
                return workspaces[index];
        }

        return null;
    }

    function isActive(id) {
        const workspace = workspaceFor(id);
        return workspace !== null && workspace.focused;
    }

    function isOccupied(id) {
        return toplevelCount(id) > 0;
    }

    function toplevelCount(id) {
        const toplevels = Hyprland.toplevels.values;
        let count = 0;

        for (let index = 0; index < toplevels.length; index++) {
            const workspace = toplevels[index].workspace;

            if (workspace !== null && workspace.id === id)
                count++;
        }

        return count;
    }

    function isUrgent(id) {
        const toplevels = Hyprland.toplevels.values;

        for (let index = 0; index < toplevels.length; index++) {
            const toplevel = toplevels[index];

            if (toplevel.urgent && toplevel.workspace !== null
                    && toplevel.workspace.id === id)
                return true;
        }

        return false;
    }

    function switcherToplevels() {
        return Hyprland.toplevels.values.filter(toplevel =>
            toplevel.workspace !== null && toplevel.workspace.id > 0
                && toplevel.address !== "").sort((left, right) => {
            if (left.activated !== right.activated)
                return left.activated ? -1 : 1;

            const leftHistory = Number(left.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);
            const rightHistory = Number(right.lastIpcObject?.focusHistoryID ?? Number.MAX_SAFE_INTEGER);

            if (leftHistory !== rightHistory)
                return leftHistory - rightHistory;
            return left.title.localeCompare(right.title);
        });
    }

    function switchTo(id) {
        if (id < 1 || id > 21)
            return;

        workspaceDispatcher.command = [
            "hyprctl", "dispatch",
            "hl.dsp.focus({ workspace = " + id + " })"
        ];
        workspaceDispatcher.running = true;
    }

    function focusToplevel(toplevel) {
        if (toplevel === null || !/^(?:0x)?[0-9a-f]+$/i.test(toplevel.address))
            return;

        const address = toplevel.address.startsWith("0x")
            ? toplevel.address : "0x" + toplevel.address;
        toplevelDispatcher.command = [
            "hyprctl", "dispatch",
            "hl.dsp.focus({ window = \"address:" + address + "\" })"
        ];
        toplevelDispatcher.running = true;
    }

    // Sends a window to a workspace and stays where you are.
    function moveToWorkspace(toplevel, id) {
        const dispatch = toplevel === null ? null : WorkspaceOverview.moveDispatch(toplevel.address, id);

        if (dispatch === null)
            return;

        moveDispatcher.command = ["hyprctl", "dispatch", dispatch];
        moveDispatcher.running = true;
    }

    // Moves a window to a workspace that doesn't exist yet, which ends up on
    // the monitor named.
    function moveToNewWorkspace(toplevel, id, monitor) {
        const batch = toplevel === null
            ? null : WorkspaceOverview.newWorkspaceBatch(toplevel.address, id, monitor);

        if (batch === null)
            return;

        moveDispatcher.command = ["hyprctl", "--batch", batch];
        moveDispatcher.running = true;
    }

    property var workspaceRulesReader: Process {
        id: workspaceRulesReader

        command: ["hyprctl", "workspacerules", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaceRules = JSON.parse(text);
                } catch (error) {
                    console.warn("WorkspaceService: unreadable workspace rules:", error);
                }
            }
        }
    }

    property var workspaceDispatcher: Process {
        id: workspaceDispatcher
    }

    property var toplevelDispatcher: Process {
        id: toplevelDispatcher
    }

    property var moveDispatcher: Process {
        id: moveDispatcher
    }
}
