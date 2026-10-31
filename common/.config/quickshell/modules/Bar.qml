import Quickshell
import QtQuick
import "../components/bar" as BarComponents
import "OpenPopup.js" as OpenPopup

// A bar on every monitor, and which of their popups is open (OpenPopup.js).
// Its settings button opens the settings panel on that bar. The control
// center (the bell's popup) opens collapsed from the bell and SUPER+N, and
// expanded from SUPER+C; its tiles ask the shell for the panels they open.
Scope {
    id: root

    required property var appearance
    required property var monitors
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    required property var clipboardHistory
    required property var nightLight
    required property var plugins
    required property var keepAwake
    required property var screenShares
    required property var cava
    required property var systemMonitor
    required property var workspaceService
    required property var settings
    required property var osd

    property var openPopup: OpenPopup.none
    // The stage the control center takes the next time it opens.
    property string controlCenterStage: "collapsed"

    // The control center's tiles asked for these; the control center module
    // opens them (modules/ControlCenter.qml).
    signal audioOutputsRequested()
    signal clipboardRequested()
    signal powerMenuRequested()
    signal screenCaptureRequested()

    // IPC toggles `popup` on the focused monitor's bar; when that bar lacks
    // the popup's element, the popup opens at its right edge.
    function togglePopupOnFocusedBar(popup) {
        root.openPopup = OpenPopup.toggledOnFocusedBar(root.openPopup, popup, bars(),
            root.workspaceService.focusedMonitorDescription());
    }

    // `stage` is "collapsed" (SUPER+N) or "expanded" (SUPER+C).
    function toggleControlCenter(stage) {
        root.controlCenterStage = stage;
        togglePopupOnFocusedBar("controlCenter");
    }

    // Opens the control center on the focused bar; it stays open if it is.
    function openControlCenter(stage) {
        root.controlCenterStage = stage;
        root.openPopup = OpenPopup.openedOnFocusedBar(root.openPopup, "controlCenter", bars(),
            root.workspaceService.focusedMonitorDescription());
    }

    function closePopup() {
        root.openPopup = OpenPopup.none;
    }

    function bars() {
        const bars = [];
        for (let index = 0; index < barWindows.instances.length; index++) {
            const panel = barWindows.instances[index];
            bars.push({ window: panel, monitor: panel.monitorDescription, visible: panel.visible });
        }
        return bars;
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
        clipboardHistory: root.clipboardHistory
        nightLight: root.nightLight
        controlsEnabled: root.plugins.controlCenterEnabled
        controlCenterStage: root.controlCenterStage
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
            // The bell opens the control center collapsed.
            if (popup === "controlCenter")
                root.controlCenterStage = "collapsed";
            root.openPopup = OpenPopup.requested(root.openPopup, popup, panelWindow);
        }

        onPopupClosed: function(popup, panelWindow) {
            root.openPopup = OpenPopup.closed(root.openPopup, popup, panelWindow);
        }

        onAudioOutputSelected: function(output) {
            root.osd.showAudioOutput(output);
        }

        onDoNotDisturbToggled: root.appearance.doNotDisturb = !root.appearance.doNotDisturb
        onAudioOutputsRequested: root.audioOutputsRequested()
        onClipboardRequested: root.clipboardRequested()
        onPowerMenuRequested: root.powerMenuRequested()
        onScreenCaptureRequested: root.screenCaptureRequested()
    }
}
