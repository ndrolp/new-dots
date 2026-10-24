import QtQuick
import "." as Panels

// The Wallpapers section: Hyprland's connected monitors handed to the
// section's settings as plain displays.
Panels.WallpaperSettingsBody {
    id: root

    property var monitors

    displays: connectedDisplays.values

    Panels.ConnectedDisplays {
        id: connectedDisplays
    }
}
