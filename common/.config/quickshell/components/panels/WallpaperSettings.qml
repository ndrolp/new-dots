import Quickshell.Hyprland
import QtQuick
import "." as Panels

// The Wallpapers section: Hyprland's connected monitors handed to the
// section's settings as plain displays.
Panels.WallpaperSettingsBody {
    id: root

    property var monitors

    displays: Hyprland.monitors.values
        .filter(monitor => monitor.description !== "")
        .map(monitor => ({
            description: monitor.description,
            portrait: root.wallpapers.isPortraitMonitor(monitor)
        }))
}
