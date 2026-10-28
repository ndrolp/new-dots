import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import QtQuick
import "components/bar" as Bar
import "components/panels" as Panels
import "components/widgets" as Widgets
import "config" as Config
import "config/SchemaMigrations.js" as SchemaMigrations
import "services" as Services

ShellRoot {
    id: shell

    property bool configOpen: false
    property var configScreen: null
    property var configWindow: null
    property var notificationWindow: null
    property string statusPopup: ""
    property var statusPopupWindow: null
    property bool notificationPanelOpen: false
    property bool wallpaperSelectorOpen: false
    property bool themeSelectorOpen: false
    property bool applicationLauncherOpen: false
    property bool powerMenuOpen: false
    property bool clipboardSelectorOpen: false
    property bool quickSearchOpen: false
    property bool unifiedSearchOpen: false
    property bool audioSinkSelectorOpen: false
    property bool commandLauncherOpen: false
    property bool windowSwitcherOpen: false
    property bool workspaceOverviewOpen: false
    property bool screenCaptureOpen: false
    property bool controlCenterOpen: false
    property bool quickSettingsOpen: false
    property bool lowBatteryNotificationSent: false

    Config.Theme {
        id: theme
    }

    Config.Appearance {
        id: appearance
    }

    // Assigns a bar profile to the focused monitor.
    function setBarProfile(profileName) {
        monitors.setDisplaySetting(workspaceService.focusedMonitorDescription(),
            "barProfile", profileName);
        osdPopup.showBarProfile(profileName.charAt(0).toUpperCase() + profileName.slice(1));
    }

    Config.Monitors {
        id: monitors
    }

    Config.SchemaMigration {
        appearance: appearance
        monitors: monitors
    }

    // A monitor seen for the first time gets the default bar profile,
    // explicitly, once both files are loaded in the current schema.
    function assignNewMonitors() {
        if (!appearance.loaded || appearance.schemaVersion !== SchemaMigrations.schemaVersion)
            return;

        // Hyprland fills in descriptions after listing a monitor; until then
        // the monitor is not named the way monitors.json names it.
        const names = Hyprland.monitors.values.filter(monitor => monitor.description !== "")
            .map(monitor => monitor.description);
        monitors.assignNewMonitors(names, appearance.barProfiles);
    }

    Variants {
        model: Hyprland.monitors.values

        delegate: QtObject {
            required property var modelData
            readonly property string description: modelData.description

            onDescriptionChanged: shell.assignNewMonitors()
            Component.onCompleted: shell.assignNewMonitors()
        }
    }

    Connections {
        target: appearance

        function onSchemaVersionChanged() {
            shell.assignNewMonitors();
        }

        function onLoadedChanged() {
            shell.assignNewMonitors();
        }
    }

    Connections {
        target: monitors

        function onLoadedChanged() {
            shell.assignNewMonitors();
        }

        function onReloadPendingChanged() {
            shell.assignNewMonitors();
        }

        function onDisplaySettingsChanged() {
            shell.assignNewMonitors();
        }
    }

    Config.Wallpapers {
        id: wallpapers
    }

    Config.Bookmarks {
        id: bookmarks
    }

    Config.Plugins {
        id: plugins
    }

    Connections {
        target: plugins

        function onApplicationLauncherEnabledChanged() {
            if (!plugins.applicationLauncherEnabled)
                shell.applicationLauncherOpen = false;
        }

        function onClipboardEnabledChanged() {
            if (!plugins.clipboardEnabled)
                shell.clipboardSelectorOpen = false;
        }

        function onQuickSearchEnabledChanged() {
            if (!plugins.quickSearchEnabled)
                shell.quickSearchOpen = false;
        }

        function onUnifiedSearchEnabledChanged() {
            if (!plugins.unifiedSearchEnabled)
                shell.unifiedSearchOpen = false;
        }

        function onCommandLauncherEnabledChanged() {
            if (!plugins.commandLauncherEnabled)
                shell.commandLauncherOpen = false;
        }

        function onQuickSettingsEnabledChanged() {
            if (!plugins.quickSettingsEnabled)
                shell.quickSettingsOpen = false;
        }

        function onScreenCaptureEnabledChanged() {
            if (!plugins.screenCaptureEnabled)
                shell.screenCaptureOpen = false;
        }

        function onControlCenterEnabledChanged() {
            if (!plugins.controlCenterEnabled)
                shell.controlCenterOpen = false;
        }
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

    Services.Cava {
        id: cava
    }

    Services.SystemMonitor {
        id: systemMonitor
    }

    Services.ClipboardHistory {
        id: clipboardHistory
    }

    Services.LauncherHistory {
        id: launcherHistory

        recentLimit: plugins.launcherRecentLimit
    }

    Services.ScreenCapture {
        id: screenCapture
    }

    Services.KeepAwake {
        id: keepAwake
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
        targetWindow: shell.notificationWindow

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
        enabled: plugins.applicationLauncherEnabled
        open: shell.applicationLauncherOpen && plugins.applicationLauncherEnabled

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
        imagePreviewsEnabled: plugins.clipboardImagePreviewsEnabled
        open: shell.clipboardSelectorOpen && plugins.clipboardEnabled

        onCloseRequested: shell.clipboardSelectorOpen = false
    }

    Panels.QuickSearch {
        appearance: appearance
        bookmarks: bookmarks
        open: shell.quickSearchOpen && plugins.quickSearchEnabled

        onCloseRequested: shell.quickSearchOpen = false
    }

    Panels.UnifiedSearch {
        appearance: appearance
        bookmarks: bookmarks
        clipboardHistory: clipboardHistory
        monitors: monitors
        workspaceService: workspaceService
        open: shell.unifiedSearchOpen && plugins.unifiedSearchEnabled

        onCloseRequested: shell.unifiedSearchOpen = false
        onSettingsRequested: {
            shell.unifiedSearchOpen = false;
            shell.configOpen = true;
            if (shell.configScreen === null)
                shell.configScreen = Quickshell.screens.values[0];
        }
    }

    Panels.AudioSinkSelector {
        appearance: appearance
        open: shell.audioSinkSelectorOpen

        onCloseRequested: shell.audioSinkSelectorOpen = false
        onSinkSelected: sink => osdPopup.showAudioSink(sink)
    }

    Panels.CommandLauncher {
        appearance: appearance
        open: shell.commandLauncherOpen && plugins.commandLauncherEnabled

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
        open: shell.screenCaptureOpen && plugins.screenCaptureEnabled

        onCloseRequested: shell.screenCaptureOpen = false
    }

    Panels.ControlCenter {
        appearance: appearance
        monitors: monitors
        workspaceService: workspaceService
        clipboardHistory: clipboardHistory
        screenCapture: screenCapture
        systemMonitor: systemMonitor
        keepAwake: keepAwake
        open: shell.controlCenterOpen && plugins.controlCenterEnabled

        onCloseRequested: shell.controlCenterOpen = false
        onAudioSinksRequested: shell.audioSinkSelectorOpen = true
        onClipboardRequested: {
            if (!plugins.clipboardEnabled)
                return;

            shell.controlCenterOpen = false;
            shell.clipboardSelectorOpen = true;
        }

        onPowerMenuRequested: {
            shell.controlCenterOpen = false;
            shell.powerMenuOpen = true;
        }
        onScreenCaptureRequested: {
            if (!plugins.screenCaptureEnabled)
                return;

            shell.controlCenterOpen = false;
            shell.screenCaptureOpen = true;
        }
    }

    Panels.QuickSettings {
        appearance: appearance
        open: shell.quickSettingsOpen && plugins.quickSettingsEnabled

        onCloseRequested: shell.quickSettingsOpen = false
        onAudioSinksRequested: {
            shell.quickSettingsOpen = false;
            shell.audioSinkSelectorOpen = true;
        }
        onControlCenterRequested: {
            if (!plugins.controlCenterEnabled)
                return;

            shell.quickSettingsOpen = false;
            shell.controlCenterOpen = true;
        }
        onSettingsRequested: {
            shell.quickSettingsOpen = false;
            shell.configOpen = true;
            if (shell.configScreen === null)
                shell.configScreen = Quickshell.screens.values[0];
        }
        onThemeSelectorRequested: {
            shell.quickSettingsOpen = false;
            shell.themeSelectorOpen = true;
        }
        onWallpaperSelectorRequested: {
            shell.quickSettingsOpen = false;
            shell.wallpaperSelectorOpen = true;
        }
        onPowerMenuRequested: {
            shell.quickSettingsOpen = false;
            shell.powerMenuOpen = true;
        }
        onProfileRequested: profile => {
            shell.quickSettingsOpen = false;
            shell.setBarProfile(profile);
        }
    }

    Panels.ConfigPanelWindow {
        appearance: appearance
        monitors: monitors
        wallpapers: wallpapers
        bookmarks: bookmarks
        plugins: plugins
        cava: cava
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
            if (shell.notificationWindow === null)
                shell.notificationWindow = shell.configWindow;
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
            if (!plugins.commandLauncherEnabled)
                return;

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
            if (!plugins.screenCaptureEnabled)
                return;

            shell.screenCaptureOpen = !shell.screenCaptureOpen;
        }
    }

    IpcHandler {
        target: "control-center"

        function toggle() {
            if (!plugins.controlCenterEnabled)
                return;

            shell.controlCenterOpen = !shell.controlCenterOpen;
        }
    }

    IpcHandler {
        target: "quick-settings"

        function toggle() {
            if (!plugins.quickSettingsEnabled)
                return;

            shell.quickSettingsOpen = !shell.quickSettingsOpen;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            if (!plugins.applicationLauncherEnabled)
                return;

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
            if (!plugins.clipboardEnabled)
                return;

            shell.clipboardSelectorOpen = !shell.clipboardSelectorOpen;
        }
    }

    IpcHandler {
        target: "quick-search"

        function toggle() {
            if (!plugins.quickSearchEnabled)
                return;

            shell.quickSearchOpen = !shell.quickSearchOpen;
        }
    }

    IpcHandler {
        target: "unified-search"

        function toggle() {
            if (!plugins.unifiedSearchEnabled)
                return;

            shell.unifiedSearchOpen = !shell.unifiedSearchOpen;
        }
    }

    IpcHandler {
        target: "bar-profiles"

        function minimal() {
            shell.setBarProfile("minimal");
        }

        function work() {
            shell.setBarProfile("work");
        }

        function media() {
            shell.setBarProfile("media");
        }

        function presentation() {
            shell.setBarProfile("presentation");
        }
    }

    Bar.Bar {
        appearance: appearance
        configOpen: shell.configOpen
        activeStatusPopup: shell.statusPopup
        activeStatusPopupWindow: shell.statusPopupWindow
        monitors: monitors
        pomodoro: pomodoro
        notificationHistory: notificationHistory
        screenCapture: screenCapture
        keepAwake: keepAwake
        cava: cava
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

            if (shell.notificationWindow === null)
                shell.notificationWindow = panelWindow;
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

        onNotificationRequested: function(panelWindow) {
            shell.notificationWindow = panelWindow;
            shell.notificationPanelOpen = !shell.notificationPanelOpen;
        }
    }
}
