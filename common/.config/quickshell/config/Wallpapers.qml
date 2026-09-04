import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

QtObject {
    id: root

    property alias assignments: settings.assignments
    property alias horizontalFolder: settings.horizontalFolder
    property alias verticalFolder: settings.verticalFolder
    property alias dynamicEnabled: settings.dynamicEnabled
    property alias dynamicIntervalMinutes: settings.dynamicIntervalMinutes

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

    function isPortraitMonitor(monitor) {
        const transform = Number(monitor.lastIpcObject.transform);

        if (transform === 1 || transform === 3)
            return true;
        if (transform === 0 || transform === 2)
            return false;

        return monitor.height > monitor.width;
    }

    function nextWallpaper(model, folder, currentPath) {
        if (model.count < 2 || folder === "")
            return "";

        let currentIndex = -1;
        for (let index = 0; index < model.count; index++) {
            if (folder + "/" + model.get(index, "fileName") === currentPath) {
                currentIndex = index;
                break;
            }
        }

        return folder + "/" + model.get((currentIndex + 1) % model.count, "fileName");
    }

    function advanceAll() {
        const monitors = Hyprland.monitors.values;

        for (let index = 0; index < monitors.length; index++) {
            const monitor = monitors[index];
            if (monitor.description === "")
                continue;

            const portrait = isPortraitMonitor(monitor);
            const folder = portrait ? verticalFolder : horizontalFolder;
            const model = portrait ? verticalWallpapers : horizontalWallpapers;
            const nextPath = nextWallpaper(model, folder, pathFor(monitor.description));

            if (nextPath !== "")
                setWallpaper(monitor.description, nextPath);
        }
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

    property var horizontalWallpapers: FolderListModel {
        id: horizontalWallpapers

        folder: root.horizontalFolder === "" ? "" : Qt.resolvedUrl(root.horizontalFolder)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    property var verticalWallpapers: FolderListModel {
        id: verticalWallpapers

        folder: root.verticalFolder === "" ? "" : Qt.resolvedUrl(root.verticalFolder)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    property var dynamicTimer: Timer {
        interval: Math.max(1, root.dynamicIntervalMinutes) * 60000
        running: root.dynamicEnabled
        repeat: true
        onTriggered: root.advanceAll()
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
            property bool dynamicEnabled: false
            property int dynamicIntervalMinutes: 30
        }
    }
}
