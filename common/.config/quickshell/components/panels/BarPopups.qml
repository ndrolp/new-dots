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
    // The app menu module (modules/AppMenu.qml).
    required property var appMenu
    required property var systemMonitor
    // The control center module (modules/ControlCenter.qml): its services,
    // stage and the panels its tiles open, handed to its popup as one.
    required property var controlCenter
    property string activePopup: ""
    // Which of the app menu's menus its Popup shows (AppMenuPopup.menuId).
    property string appMenuId: ""
    // Where the open popup sits, { popup, edge, left, right, resizing }, or null.
    // Left and right are the ends of its span along the bar, as with zones: on a
    // side bar they are its top and bottom. `resizing` is true while it holds its
    // window through a stage change.
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
}
