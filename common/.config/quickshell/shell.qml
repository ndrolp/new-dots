import Quickshell
import QtQuick
import "components/panels" as Panels
import "components/widgets" as Widgets
import "config" as Config
import "modules" as Modules
import "services" as Services

// Puts the shell together: the config files and services are created once
// here and handed to each part. Each part in modules/ owns whether it is
// open and its IPC handler.
ShellRoot {
    id: shell

    Config.Theme {
        id: theme
    }

    Config.Appearance {
        id: appearance
    }

    Config.Monitors {
        id: monitors
    }

    Config.SchemaMigration {
        appearance: appearance
        monitors: monitors
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

    Services.ScreenShares {
        id: screenShares
    }

    Services.NightLight {
        id: nightLight

        appearance: appearance
    }

    Modules.Lock {
        wallpapers: wallpapers
    }

    Modules.LowBattery {}

    Modules.Osd {
        id: osd

        appearance: appearance
    }

    Modules.BarProfiles {
        id: barProfiles

        appearance: appearance
        monitors: monitors
        workspaceService: workspaceService
        osd: osd
    }

    Modules.Notifications {
        id: notifications

        appearance: appearance
        notificationHistory: notificationHistory
        fallbackWindow: settings.window
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

    Modules.WallpaperSelector {
        id: wallpaperSelector

        appearance: appearance
        wallpapers: wallpapers
    }

    Modules.ThemeSelector {
        id: themeSelector

        appearance: appearance
    }

    Modules.ApplicationLauncher {
        appearance: appearance
        launcherHistory: launcherHistory
        plugins: plugins
    }

    Modules.PowerMenu {
        id: powerMenu

        appearance: appearance
    }

    Modules.ClipboardSelector {
        id: clipboardSelector

        appearance: appearance
        clipboardHistory: clipboardHistory
        plugins: plugins
    }

    Modules.QuickSearch {
        appearance: appearance
        bookmarks: bookmarks
        plugins: plugins
    }

    Modules.UnifiedSearch {
        appearance: appearance
        bookmarks: bookmarks
        clipboardHistory: clipboardHistory
        monitors: monitors
        workspaceService: workspaceService
        plugins: plugins
        settings: settings
        keybindCheatsheet: keybindCheatsheet
    }

    Modules.KeybindCheatsheet {
        id: keybindCheatsheet

        appearance: appearance
    }

    Modules.AudioSinkSelector {
        id: audioSinkSelector

        appearance: appearance
        osd: osd
    }

    Modules.CommandLauncher {
        appearance: appearance
        plugins: plugins
    }

    Modules.WindowSwitcher {
        appearance: appearance
        workspaceService: workspaceService
    }

    Modules.WorkspaceOverview {
        appearance: appearance
        monitors: monitors
        workspaceService: workspaceService
    }

    Modules.ScreenCapture {
        id: screenCaptureChooser

        appearance: appearance
        screenCapture: screenCapture
        plugins: plugins
    }

    Modules.ControlCenter {
        id: controlCenter

        appearance: appearance
        monitors: monitors
        workspaceService: workspaceService
        clipboardHistory: clipboardHistory
        screenCapture: screenCapture
        systemMonitor: systemMonitor
        keepAwake: keepAwake
        nightLight: nightLight
        plugins: plugins
        audioSinkSelector: audioSinkSelector
        clipboardSelector: clipboardSelector
        powerMenu: powerMenu
        screenCaptureChooser: screenCaptureChooser
    }

    Modules.QuickSettings {
        appearance: appearance
        plugins: plugins
        barProfiles: barProfiles
        audioSinkSelector: audioSinkSelector
        controlCenter: controlCenter
        settings: settings
        themeSelector: themeSelector
        wallpaperSelector: wallpaperSelector
        powerMenu: powerMenu
    }

    Modules.Settings {
        id: settings

        appearance: appearance
        monitors: monitors
        wallpapers: wallpapers
        bookmarks: bookmarks
        plugins: plugins
        cava: cava
    }

    Modules.Bar {
        appearance: appearance
        monitors: monitors
        pomodoro: pomodoro
        notificationHistory: notificationHistory
        screenCapture: screenCapture
        keepAwake: keepAwake
        screenShares: screenShares
        cava: cava
        systemMonitor: systemMonitor
        workspaceService: workspaceService
        settings: settings
        notifications: notifications
        osd: osd
    }
}
