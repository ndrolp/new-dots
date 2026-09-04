import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import QtQuick
import "components/bar" as Bar
import "components/panels" as Panels
import "components/widgets" as Widgets
import "config" as Config
import "services" as Services

ShellRoot {
    id: shell

    property bool configOpen: false
    property var configScreen: null
    property var configWindow: null
    property string statusPopup: ""
    property var statusPopupWindow: null
    property bool notificationPanelOpen: false
    property bool wallpaperSelectorOpen: false
    property bool themeSelectorOpen: false
    property bool applicationLauncherOpen: false
    property bool powerMenuOpen: false
    property bool clipboardSelectorOpen: false
    property bool quickSearchOpen: false
    property bool audioSinkSelectorOpen: false
    property bool commandLauncherOpen: false
    property bool windowSwitcherOpen: false
    property bool workspaceOverviewOpen: false
    property bool screenCaptureOpen: false
    property bool controlCenterOpen: false
    property bool lowBatteryNotificationSent: false

    Config.Theme {
        id: theme
    }

    Config.Appearance {
        id: appearance
    }

    Config.Monitors {
        id: monitors
    }

    Config.Wallpapers {
        id: wallpapers
    }

    Config.Bookmarks {
        id: bookmarks
    }

    Services.WorkspaceService {
        id: workspaceService
    }

    Services.Pomodoro {
        id: pomodoro
    }

    Services.NotificationHistory {
        id: notificationHistory
    }

    Services.SystemMonitor {
        id: systemMonitor
    }

    Services.ClipboardHistory {
        id: clipboardHistory
    }

    Services.LauncherHistory {
        id: launcherHistory
    }

    Services.ScreenCapture {
        id: screenCapture
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = !appearance.doNotDisturb;
            notificationHistory.add(notification);

            if (!appearance.doNotDisturb)
                notificationSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"]);
        }
    }

    Connections {
        target: appearance

        function onDoNotDisturbChanged() {
            if (!appearance.doNotDisturb)
                return;

            notificationServer.trackedNotifications.forEach(notification => {
                notification.tracked = false;
            });
        }
    }

    Process {
        id: notificationSound
    }

    Process {
        id: lowBatteryNotification
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const battery = UPower.displayDevice;
            const discharging = battery
                && battery.state === UPowerDeviceState.Discharging;
            const critical = discharging && battery.percentage <= 0.15;

            if (critical && !shell.lowBatteryNotificationSent) {
                lowBatteryNotification.command = [
                    "notify-send", "-u", "critical", "-i", "battery-caution",
                    "Battery low", Math.round(battery.percentage * 100) + "% remaining"
                ];
                lowBatteryNotification.running = true;
                shell.lowBatteryNotificationSent = true;
            } else if (!critical) {
                shell.lowBatteryNotificationSent = false;
            }
        }
    }

    Panels.NotificationPopup {
        appearance: appearance
        notificationServer: notificationServer
    }

    Panels.NotificationPanel {
        appearance: appearance
        notificationServer: notificationServer
        notificationHistory: notificationHistory
        open: shell.notificationPanelOpen
        targetWindow: shell.configWindow

        onCloseRequested: shell.notificationPanelOpen = false
    }

    Panels.OsdPopup {
        id: osdPopup

        appearance: appearance
    }

    Panels.BackgroundClock {
        appearance: appearance
        monitors: monitors
    }

    Widgets.DesktopWidgets {
        appearance: appearance
        monitors: monitors
        systemMonitor: systemMonitor
    }

    Panels.WallpaperSelector {
        appearance: appearance
        wallpapers: wallpapers
        open: shell.wallpaperSelectorOpen

        onCloseRequested: shell.wallpaperSelectorOpen = false
    }

    Panels.ThemeSelector {
        open: shell.themeSelectorOpen

        onCloseRequested: shell.themeSelectorOpen = false
    }

    Panels.ApplicationLauncher {
        appearance: appearance
        launcherHistory: launcherHistory
        open: shell.applicationLauncherOpen

        onCloseRequested: shell.applicationLauncherOpen = false
    }

    Panels.PowerMenu {
        appearance: appearance
        open: shell.powerMenuOpen

        onCloseRequested: shell.powerMenuOpen = false
    }

    Panels.ClipboardSelector {
        appearance: appearance
        clipboardHistory: clipboardHistory
        open: shell.clipboardSelectorOpen

        onCloseRequested: shell.clipboardSelectorOpen = false
    }

    Panels.QuickSearch {
        appearance: appearance
        bookmarks: bookmarks
        open: shell.quickSearchOpen

        onCloseRequested: shell.quickSearchOpen = false
    }

    Panels.AudioSinkSelector {
        appearance: appearance
        open: shell.audioSinkSelectorOpen

        onCloseRequested: shell.audioSinkSelectorOpen = false
        onSinkSelected: sink => osdPopup.showAudioSink(sink)
    }

    Panels.CommandLauncher {
        appearance: appearance
        open: shell.commandLauncherOpen

        onCloseRequested: shell.commandLauncherOpen = false
    }

    Panels.WindowSwitcher {
        id: windowSwitcher

        appearance: appearance
        workspaceService: workspaceService
        open: shell.windowSwitcherOpen

        onOpenRequested: shell.windowSwitcherOpen = true
        onCloseRequested: shell.windowSwitcherOpen = false
    }

    Panels.WorkspaceOverview {
        appearance: appearance
        monitors: monitors
        workspaceService: workspaceService
        open: shell.workspaceOverviewOpen

        onCloseRequested: shell.workspaceOverviewOpen = false
    }

    Panels.ScreenCapture {
        appearance: appearance
        screenCapture: screenCapture
        open: shell.screenCaptureOpen

        onCloseRequested: shell.screenCaptureOpen = false
    }

    Panels.ControlCenter {
        appearance: appearance
        clipboardHistory: clipboardHistory
        screenCapture: screenCapture
        systemMonitor: systemMonitor
        open: shell.controlCenterOpen

        onCloseRequested: shell.controlCenterOpen = false
        onAudioSinksRequested: shell.audioSinkSelectorOpen = true
        onClipboardRequested: {
            shell.controlCenterOpen = false;
            shell.clipboardSelectorOpen = true;
        }
        onPowerMenuRequested: {
            shell.controlCenterOpen = false;
            shell.powerMenuOpen = true;
        }
        onScreenCaptureRequested: {
            shell.controlCenterOpen = false;
            shell.screenCaptureOpen = true;
        }
    }

    Panels.ConfigPanelWindow {
        appearance: appearance
        monitors: monitors
        wallpapers: wallpapers
        bookmarks: bookmarks
        open: shell.configOpen
        targetWindow: shell.configWindow

        onCloseRequested: shell.configOpen = false
    }

    IpcHandler {
        target: "config"

        function toggle() {
            shell.configOpen = !shell.configOpen;

            if (shell.configScreen === null)
                shell.configScreen = Quickshell.screens.values[0];
        }
    }

    IpcHandler {
        target: "osd"

        function volume() {
            osdPopup.showVolume();
        }

        function brightness() {
            osdPopup.showBrightness();
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle() {
            shell.notificationPanelOpen = !shell.notificationPanelOpen;
        }
    }

    IpcHandler {
        target: "wallpapers"

        function toggle() {
            shell.wallpaperSelectorOpen = !shell.wallpaperSelectorOpen;
        }
    }

    IpcHandler {
        target: "themes"

        function toggle() {
            shell.themeSelectorOpen = !shell.themeSelectorOpen;
        }
    }

    IpcHandler {
        target: "audio-sinks"

        function toggle() {
            shell.audioSinkSelectorOpen = !shell.audioSinkSelectorOpen;
        }
    }

    IpcHandler {
        target: "command-launcher"

        function toggle() {
            shell.commandLauncherOpen = !shell.commandLauncherOpen;
        }
    }

    IpcHandler {
        target: "window-switcher"

        function next() {
            windowSwitcher.cycle(1);
        }

        function previous() {
            windowSwitcher.cycle(-1);
        }

        function close() {
            shell.windowSwitcherOpen = false;
        }
    }

    IpcHandler {
        target: "workspace-overview"

        function toggle() {
            shell.workspaceOverviewOpen = !shell.workspaceOverviewOpen;
        }
    }

    IpcHandler {
        target: "screen-capture"

        function toggle() {
            shell.screenCaptureOpen = !shell.screenCaptureOpen;
        }
    }

    IpcHandler {
        target: "control-center"

        function toggle() {
            shell.controlCenterOpen = !shell.controlCenterOpen;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            shell.applicationLauncherOpen = !shell.applicationLauncherOpen;
        }
    }

    IpcHandler {
        target: "power"

        function toggle() {
            shell.powerMenuOpen = !shell.powerMenuOpen;
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            shell.clipboardSelectorOpen = !shell.clipboardSelectorOpen;
        }
    }

    IpcHandler {
        target: "quick-search"

        function toggle() {
            shell.quickSearchOpen = !shell.quickSearchOpen;
        }
    }

    Bar.Bar {
        appearance: appearance
        configOpen: shell.configOpen
        activeStatusPopup: shell.statusPopup
        activeStatusPopupWindow: shell.statusPopupWindow
        monitors: monitors
        pomodoro: pomodoro
        systemMonitor: systemMonitor
        workspaceService: workspaceService

        onConfigRequested: function(screen, panelWindow) {
            if (shell.configOpen && shell.configWindow === panelWindow) {
                shell.configOpen = false;
            } else {
                shell.configScreen = screen;
                shell.configWindow = panelWindow;
                shell.configOpen = true;
            }
        }

        onPanelReady: function(screen, panelWindow) {
            if (shell.configWindow === null) {
                shell.configScreen = screen;
                shell.configWindow = panelWindow;
            }
        }

        onStatusPopupRequested: function(popup, panelWindow) {
            if (shell.statusPopup === popup && shell.statusPopupWindow === panelWindow) {
                shell.statusPopup = "";
                shell.statusPopupWindow = null;
            } else {
                shell.statusPopup = popup;
                shell.statusPopupWindow = panelWindow;
            }
        }

        onStatusPopupClosed: function(popup, panelWindow) {
            if (shell.statusPopup === popup && shell.statusPopupWindow === panelWindow) {
                shell.statusPopup = "";
                shell.statusPopupWindow = null;
            }
        }

        onAudioSinkSelected: function(sink) {
            osdPopup.showAudioSink(sink);
        }
    }
}
