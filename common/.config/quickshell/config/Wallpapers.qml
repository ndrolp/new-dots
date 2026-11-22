import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "WallpaperModel.js" as WallpaperModel

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
        if (monitorDescription === "")
            return;

        assign(monitorDescription, path);
        apply(monitorDescription, localPath(path));
    }

    // Makes `path` the monitor's wallpaper without showing it again: the
    // capsule's wallpaper picker keeps the one it is previewing.
    function assign(monitorDescription, path) {
        if (monitorDescription === "")
            return;

        assignments = WallpaperModel.withAssignment(
            assignments, monitorDescription, localPath(path));
    }

    // Shows `path` on the monitor without making it its wallpaper: the
    // capsule's wallpaper picker previews each one it moves to. A quick fade,
    // and each preview its own awww call, so moving fast never waits on the
    // one before.
    function preview(monitorDescription, path) {
        const output = outputFor(monitorDescription);
        const localWallpaperPath = localPath(path);
        if (output === "" || localWallpaperPath === "")
            return;

        Quickshell.execDetached(["awww", "img", "-o", output, localWallpaperPath,
            "--transition-type", "fade", "--transition-duration", "0.4"]);
    }

    // Shows the monitor's own wallpaper again after a preview.
    function restore(monitorDescription) {
        preview(monitorDescription, pathFor(monitorDescription));
    }

    // The Hyprland output name of the monitor, or "" when it isn't connected.
    function outputFor(monitorDescription) {
        const monitors = Hyprland.monitors.values;
        for (let index = 0; index < monitors.length; index++) {
            if (monitors[index].description === monitorDescription)
                return monitors[index].name;
        }
        return "";
    }

    function isPortraitMonitor(monitor) {
        return WallpaperModel.isPortrait(
            monitor.lastIpcObject.transform, monitor.width, monitor.height);
    }

    function nextWallpaper(model, currentPath) {
        if (model.count < 2)
            return "";

        let currentIndex = -1;
        for (let index = 0; index < model.count; index++) {
            if (model.pathAt(index) === currentPath) {
                currentIndex = index;
                break;
            }
        }

        return model.pathAt((currentIndex + 1) % model.count);
    }

    function advanceAll() {
        const monitors = Hyprland.monitors.values;

        for (let index = 0; index < monitors.length; index++) {
            const monitor = monitors[index];
            if (monitor.description === "")
                continue;

            const portrait = isPortraitMonitor(monitor);
            const model = portrait ? verticalWallpapers : horizontalWallpapers;
            const nextPath = nextWallpaper(model, pathFor(monitor.description));

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
                    "--transition-type", "grow", "--transition-pos", "center"
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

    property var horizontalWallpapers: WallpaperFiles {
        id: horizontalWallpapers

        path: root.horizontalFolder
    }

    property var verticalWallpapers: WallpaperFiles {
        id: verticalWallpapers

        path: root.verticalFolder
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
