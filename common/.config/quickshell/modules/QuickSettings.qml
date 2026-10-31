import Quickshell.Io
import QtQuick
import "../components/panels" as Panels

Feature {
    id: root

    required property var appearance
    required property var plugins
    required property var barProfiles
    // The features its buttons open.
    required property var audioOutputSelector
    required property var controlCenter
    required property var settings
    required property var themeSelector
    required property var wallpaperSelector
    required property var powerMenu

    available: plugins.quickSettingsEnabled

    Panels.QuickSettings {
        appearance: root.appearance
        open: root.open

        onCloseRequested: root.open = false
        onAudioOutputsRequested: root.switchTo(root.audioOutputSelector)
        onControlCenterRequested: root.switchTo(root.controlCenter)
        onSettingsRequested: root.switchTo(root.settings)
        onThemeSelectorRequested: root.switchTo(root.themeSelector)
        onWallpaperSelectorRequested: root.switchTo(root.wallpaperSelector)
        onPowerMenuRequested: root.switchTo(root.powerMenu)
        onProfileRequested: profile => {
            root.open = false;
            root.barProfiles.setBarProfile(profile);
        }
    }

    IpcHandler {
        target: "quick-settings"

        function toggle() {
            root.toggle();
        }
    }
}
