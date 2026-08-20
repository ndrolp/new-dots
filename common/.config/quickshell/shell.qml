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

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => notification.tracked = true
    }

    Panels.NotificationPopup {
        appearance: appearance
        notificationServer: notificationServer
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

    Bar.Bar {
        appearance: appearance
        configOpen: shell.configOpen
        activeStatusPopup: shell.statusPopup
        activeStatusPopupWindow: shell.statusPopupWindow
        monitors: monitors
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
    }
}
