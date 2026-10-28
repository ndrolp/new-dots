import Quickshell
import QtQuick
import "../components/bar" as BarComponents
import "OpenPopup.js" as OpenPopup

// A bar on every monitor, and which of their popups is open (OpenPopup.js).
// Its settings and notifications buttons open those panels on that bar.
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
    required property var notifications
    required property var osd

    property var openPopup: OpenPopup.none

    BarComponents.Bar {
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
            root.notifications.offerWindow(panelWindow);
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

        onNotificationRequested: function(panelWindow) {
            root.notifications.toggleOn(panelWindow);
        }
    }
}
