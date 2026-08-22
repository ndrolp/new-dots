import Quickshell.Hyprland
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

    function switchTo(id) {
        Hyprland.dispatch("workspace " + id);
    }
}
