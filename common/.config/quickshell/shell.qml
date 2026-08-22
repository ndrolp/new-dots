import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "components/bar" as Bar
import "components/panels" as Panels
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

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;
            notificationHistory.add(notification);
            notificationSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/message.oga"]);
        }
    }

    Process {
        id: notificationSound
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

    Panels.ConfigPanelWindow {
        appearance: appearance
        monitors: monitors
        wallpapers: wallpapers
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
