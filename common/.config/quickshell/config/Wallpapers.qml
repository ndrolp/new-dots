import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property alias assignments: settings.assignments
    property alias horizontalFolder: settings.horizontalFolder
    property alias verticalFolder: settings.verticalFolder

    function localPath(path) {
        if (path === undefined || path === null)
            return "";

        return path.startsWith("file://") ? decodeURIComponent(path.slice(7)) : path;
    }

    function pathFor(monitorDescription) {
        return assignments[monitorDescription] || "";
    }

    function setWallpaper(monitorDescription, path) {
        const localWallpaperPath = localPath(path);
        const updated = Object.assign({}, assignments);
        updated[monitorDescription] = localWallpaperPath;
        assignments = updated;
        apply(monitorDescription, localWallpaperPath);
    }

    function apply(monitorDescription, path) {
        if (path === "")
            return;

        const monitors = Hyprland.monitors.values;
        for (let index = 0; index < monitors.length; index++) {
            if (monitors[index].description === monitorDescription) {
                const command = [
                    "awww", "img", "-o", monitors[index].name, path,
                    "--transition-type", "wipe"
                ];
                console.info("Executing:", command.join(" "));
                image.command = command;
                image.running = true;
                return;
            }
        }

        console.warn("No Hyprland output found for wallpaper monitor", monitorDescription);
    }

    property var image: Process {
        id: image

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("awww exited with code", exitCode, "status", exitStatus);
        }
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("wallpapers.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property var assignments: ({})
            property string horizontalFolder: ""
            property string verticalFolder: ""
        }
    }
}
