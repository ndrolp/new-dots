import Quickshell
import QtQuick
import "../components/bar" as BarComponents
import "OpenPopup.js" as OpenPopup

// A bar on every monitor, and which of their popups is open (OpenPopup.js).
// Its settings button opens the settings panel on that bar.
Scope {
    id: root

    required property var appearance
    required property var monitors
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    required property var keepAwake
    required property var screenShares
    required property var cava
    required property var systemMonitor
    required property var workspaceService
    required property var settings
    required property var osd

    property var openPopup: OpenPopup.none

    // IPC toggles `popup` on the focused monitor's bar; when that bar lacks
    // the popup's element, the popup opens at its right edge.
    function togglePopupOnFocusedBar(popup) {
        const bars = [];
        for (let index = 0; index < barWindows.instances.length; index++) {
            const panel = barWindows.instances[index];
            bars.push({ window: panel, monitor: panel.monitorDescription, visible: panel.visible });
        }
        root.openPopup = OpenPopup.toggledOnFocusedBar(root.openPopup, popup, bars,
            root.workspaceService.focusedMonitorDescription());
    }

    BarComponents.Bar {
        id: barWindows

        appearance: root.appearance
        configOpen: root.settings.open
        activePopup: root.openPopup.popup
        activePopupWindow: root.openPopup.window
        monitors: root.monitors
        pomodoro: root.pomodoro
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        keepAwake: root.keepAwake
        screenShares: root.screenShares
        cava: root.cava
        systemMonitor: root.systemMonitor
        workspaceService: root.workspaceService

        onConfigRequested: function(screen, panelWindow) {
            root.settings.toggleOn(screen, panelWindow);
        }

        onPanelReady: function(screen, panelWindow) {
            root.settings.offerWindow(screen, panelWindow);
        }

        onPopupRequested: function(popup, panelWindow) {
            root.openPopup = OpenPopup.requested(root.openPopup, popup, panelWindow);
        }

        onPopupClosed: function(popup, panelWindow) {
            root.openPopup = OpenPopup.closed(root.openPopup, popup, panelWindow);
        }

        onAudioOutputSelected: function(output) {
            root.osd.showAudioOutput(output);
        }

        onDoNotDisturbToggled: root.appearance.doNotDisturb = !root.appearance.doNotDisturb
    }
}
