import QtQuick
import Quickshell.Hyprland
import "../../config/WallpaperModel.js" as WallpaperModel

// Hyprland's connected monitors as plain displays, each { description, name,
// portrait }, for the settings that choose between them
// (SettingsMonitorChoice). `name` is the monitor's model, falling back to its
// output name, so the choice stays short.
QtObject {
    readonly property var values: Hyprland.monitors.values
        .filter(monitor => monitor.description !== "")
        .map(monitor => {
            const ipc = monitor.lastIpcObject || {};
            return {
                description: monitor.description,
                name: ipc.model || monitor.name,
                portrait: WallpaperModel.isPortrait(ipc.transform, monitor.width, monitor.height)
            };
        })
}
