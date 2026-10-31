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
    required property var notificationHistory
    required property var screenCapture
    required property var clipboardHistory
    // The shell's night light (services/NightLight.qml).
    required property var nightLight
    // The control center plugin; off, the control center is notifications only.
    property bool controlsEnabled: true
    // The control center's stage: the one it is at while open, the one it
    // takes the next time it opens.
    property string controlCenterStage: "collapsed"
    property string activePopup: ""
    // The bar content; places popups under the bar element that opened them.
    property var popupAnchorProvider: null
    signal popupClosed(string popup)
    signal audioOutputSelected(var output)
    // Do not disturb is a global setting, not the bar profile's: the shell
    // flips it.
    signal doNotDisturbToggled()
    // The control center's tiles ask the shell to open these panels.
    signal clipboardRequested()
    signal powerMenuRequested()
    signal screenCaptureRequested()
    // The control center's pencil: the settings panel at its section.
    signal controlCenterSettingsRequested()
    // The open control center switched stage by itself (its handle, the
    // audio output tile).
    signal controlCenterStageSwitched(string stage)

    ControlCenterPopup {
        popups: root
        notificationHistory: root.notificationHistory
        screenCapture: root.screenCapture
        clipboardHistory: root.clipboardHistory
        systemMonitor: root.systemMonitor
        keepAwake: root.keepAwake
        nightLight: root.nightLight
        controlsEnabled: root.controlsEnabled
        requestedStage: root.controlCenterStage
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
