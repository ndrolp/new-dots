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
    required property var systemMonitor
    // The control center module (modules/ControlCenter.qml): its services,
    // stage and the panels its tiles open, handed to its popup as one.
    required property var controlCenter
    property string activePopup: ""
    // Where the open popup sits, { popup, edge, left, right }, or null.
    property var openPopup: null
    // The bar content; places popups under the bar element that opened them.
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
