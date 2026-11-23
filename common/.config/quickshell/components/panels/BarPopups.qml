import QtQuick

// Every popup of one bar, each opening from its bar element. Only one is open
// at a time: the one named by `activePopup`.
Item {
    id: root

    required property var appearance
    required property var barWindow
    required property var pomodoro
    // The shell's keep-awake (services/KeepAwake.qml).
    required property var keepAwake
    // The apps using the microphone or a camera (services/DeviceCaptures.qml).
    required property var deviceCaptures
    // The app menu module (modules/AppMenu.qml).
    required property var appMenu
    required property var systemMonitor
    // The control center module (modules/ControlCenter.qml): its services,
    // stage and the panels its tiles open, handed to its popup as one.
    required property var controlCenter
    // The features that open inside a capsule instead of full-screen
    // (modules/CapsuleFeature.qml) and the settings panel (modules/Settings.qml),
    // handed to their popups: { wallpapers, launcher, clipboard, unifiedSearch,
    // quickSearch, colorschemes, powerMenu, audioOutputs, settings }.
    required property var capsuleFeatures
    // The notifications this bar's capsule shows, with notifications in the
    // capsule on (components/bar/CapsuleNotifications.qml); null elsewhere.
    property var capsuleNotifications: null
    property string activePopup: ""
    // Which of the app menu's menus its Popup shows (AppMenuPopup.menuId).
    property string appMenuId: ""
    // Where the open popup sits, { popup, edge, start, end, resizing, inside,
    // width, height, windowHeight }, or null. Start and end are its span along
    // the bar, from the left or, on a side bar, the top. `resizing` is true
    // while it holds its window through a stage change. `inside` is true
    // inside a capsule, which grows to its surface's `width` and `height`;
    // `windowHeight` is its window's, held through a stage change.
    property var openPopup: null
    // The bar content; places popups at the bar element that opened them.
    property var popupAnchorProvider: null
    signal popupClosed(string popup)
    signal audioOutputSelected(var output)

    // A closing popup clears only itself: the next one may have opened already.
    function popupPlaced(popup, placement) {
        if (placement)
            openPopup = placement;
        else if (openPopup && openPopup.popup === popup)
            openPopup = null;
    }

    ControlCenterPopup {
        popups: root
        controlCenter: root.controlCenter
    }

    SystemPopup {
        popups: root
        systemMonitor: root.systemMonitor
    }

    PomodoroPopup {
        popups: root
        pomodoro: root.pomodoro
    }

    KeepAwakePopup {
        popups: root
        keepAwake: root.keepAwake
    }

    PrivacyPopup {
        popups: root
        deviceCaptures: root.deviceCaptures
    }

    AppMenuPopup {
        popups: root
        menuId: root.appMenuId
        appMenu: root.appMenu
    }

    MediaPopup {
        popups: root
    }

    AudioPopup {
        popups: root
    }

    TrayPopup {
        popups: root
    }

    BatteryPopup {
        popups: root
        systemMonitor: root.systemMonitor
    }

    BluetoothPopup {
        popups: root
    }

    NetworkPopup {
        popups: root
    }

    WallpaperPopup {
        popups: root
        feature: root.capsuleFeatures.wallpapers
    }

    ApplicationLauncherPopup {
        popups: root
        feature: root.capsuleFeatures.launcher
    }

    ClipboardSelectorPopup {
        popups: root
        feature: root.capsuleFeatures.clipboard
    }

    UnifiedSearchPopup {
        popups: root
        feature: root.capsuleFeatures.unifiedSearch
    }

    QuickSearchPopup {
        popups: root
        feature: root.capsuleFeatures.quickSearch
    }

    ThemeSelectorPopup {
        popups: root
        feature: root.capsuleFeatures.colorschemes
    }

    PowerMenuPopup {
        popups: root
        feature: root.capsuleFeatures.powerMenu
    }

    AudioSinkSelectorPopup {
        popups: root
        feature: root.capsuleFeatures.audioOutputs
    }

    SettingsPopup {
        popups: root
        feature: root.capsuleFeatures.settings
    }

    CapsuleNotificationPopup {
        popups: root
        notification: root.capsuleNotifications ? root.capsuleNotifications.shown : null
        waiting: root.capsuleNotifications ? root.capsuleNotifications.waiting : 0
        onEnded: notification => root.capsuleNotifications.end(notification)
    }
}
