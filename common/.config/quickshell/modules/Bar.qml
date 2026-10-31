import Quickshell
import QtQuick
import "../components/bar" as BarComponents
import "OpenPopup.js" as OpenPopup

// A bar on every monitor, and which of their popups is open (OpenPopup.js).
// Its settings button opens the settings panel on that bar, and the bell
// opens the control center, its popup. The control center module
// (`controlCenter`) owns that popup's state and is handed to it; it opens and
// closes it through `openPopup`, `bars()`, `focusedMonitor()` and
// `closePopup()`.
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
    // The control center module (modules/ControlCenter.qml).
    required property var controlCenter

    property var openPopup: OpenPopup.none

    // A bar element was clicked and its popup is about to open.
    signal barElementOpening(string popup)

    function closePopup() {
        root.openPopup = OpenPopup.none;
    }

    // The bars, as OpenPopup.js takes them.
    function bars() {
        const bars = [];
        for (let index = 0; index < barWindows.instances.length; index++) {
            const panel = barWindows.instances[index];
            bars.push({ window: panel, monitor: panel.monitorDescription, visible: panel.visible });
        }
        return bars;
    }

    // The focused monitor's description: IPC opens popups on its bar.
    function focusedMonitor() {
        return root.workspaceService.focusedMonitorDescription();
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
        controlCenter: root.controlCenter
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

        // A bar element opens its popup, or closes it if it was open.
        onPopupRequested: function(popup, panelWindow) {
            const next = OpenPopup.requested(root.openPopup, popup, panelWindow);
            if (next !== OpenPopup.none)
                root.barElementOpening(next.popup);
            root.openPopup = next;
        }

        onPopupClosed: function(popup, panelWindow) {
            root.openPopup = OpenPopup.closed(root.openPopup, popup, panelWindow);
        }

        onAudioOutputSelected: function(output) {
            root.osd.showAudioOutput(output);
        }
    }
}
