import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    function monitorDescriptionForScreen(screen) {
        const monitor = Hyprland.monitorFor(screen);
        return monitor !== null && monitor.description !== "" ? monitor.description : screen.name;
    }

    function workspacesForScreen(screen, configuredWorkspaces) {
        const monitor = Hyprland.monitorFor(screen);
        const workspaceIds = configuredWorkspaces.filter(id => id >= 1 && id <= 21);
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
        const toplevels = Hyprland.toplevels.values;

        for (let index = 0; index < toplevels.length; index++) {
            const workspace = toplevels[index].workspace;

            if (workspace !== null && workspace.id === id)
                return true;
        }

        return false;
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

    function toplevelsForWorkspace(id) {
        return Hyprland.toplevels.values.filter(toplevel =>
            toplevel.workspace !== null && toplevel.workspace.id === id
                && toplevel.address !== "");
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

    property var workspaceDispatcher: Process {
        id: workspaceDispatcher
    }

    property var toplevelDispatcher: Process {
        id: toplevelDispatcher
    }
}
