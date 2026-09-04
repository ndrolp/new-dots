import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var systemMonitor

    model: Quickshell.screens

    readonly property var widgetOrder: ["media", "system", "calendar", "network", "weather"]
    readonly property int widgetGap: 10

    function widgetEnabled(widget) {
        if (widget === "media")
            return appearance.desktopMediaEnabled && Mpris.players.values.length > 0;
        if (widget === "system")
            return appearance.desktopSystemEnabled;
        if (widget === "calendar")
            return appearance.desktopCalendarEnabled;
        if (widget === "network")
            return appearance.desktopNetworkEnabled;
        return appearance.desktopWeatherEnabled;
    }

    function widgetPosition(widget) {
        if (widget === "media")
            return appearance.desktopMediaPosition;
        if (widget === "system")
            return appearance.desktopSystemPosition;
        if (widget === "calendar")
            return appearance.desktopCalendarPosition;
        if (widget === "network")
            return appearance.desktopNetworkPosition;
        return appearance.desktopWeatherPosition;
    }

    function widgetHeight(widget) {
        if (widget === "media")
            return 74;
        if (widget === "weather")
            return 62;
        if (widget === "system")
            return 96;
        if (widget === "calendar")
            return 74;
        return 72;
    }

    function stackOffset(position, widget) {
        let offset = 0;

        for (let index = 0; index < widgetOrder.length; index++) {
            const candidate = widgetOrder[index];
            if (candidate === widget)
                break;
            if (widgetEnabled(candidate) && widgetPosition(candidate) === position)
                offset += widgetHeight(candidate) + widgetGap;
        }

        return offset;
    }

    function stackHeight(position) {
        let height = 0;

        for (let index = 0; index < widgetOrder.length; index++) {
            const widget = widgetOrder[index];
            if (widgetEnabled(widget) && widgetPosition(widget) === position)
                height += widgetHeight(widget) + (height > 0 ? widgetGap : 0);
        }

        return height;
    }

    component DesktopCard: Rectangle {
        required property string widget
        required property string position
        property bool active: false

        visible: active
        radius: root.appearance.radius
        color: Qt.rgba(cardTheme.surface.r, cardTheme.surface.g, cardTheme.surface.b, 0.78)
        border.color: cardTheme.border
        border.width: 1
        x: position.endsWith("left") ? 48
            : position.endsWith("right") ? parent.width - width - 48
            : (parent.width - width) / 2
        y: position.startsWith("top") ? 82 + root.stackOffset(position, widget)
            : position.startsWith("bottom")
                ? parent.height - height - 56 - root.stackOffset(position, widget)
                : (parent.height - root.stackHeight(position)) / 2
                    + root.stackOffset(position, widget)

        Config.Theme {
            id: cardTheme
        }
    }

    delegate: PanelWindow {
        id: widgetWindow

        required property var modelData
        readonly property var hyprlandMonitor: Hyprland.monitorFor(modelData)
        readonly property string monitorDescription: hyprlandMonitor !== null
            && hyprlandMonitor.description !== "" ? hyprlandMonitor.description : modelData.name
        readonly property var player: Mpris.players.values.find(candidate => candidate.isPlaying)
            || (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)
        readonly property var wifi: {
            const devices = Networking.devices.values;
            return devices.find(device => DeviceType.toString(device.type) === "Wifi") || null;
        }
        property date currentTime: new Date()
        property string weather: "Weather unavailable"
        property real mediaPosition: 0
        property string mediaTrackKey: ""

        function updateMediaPosition() {
            const trackKey = player
                ? player.identity + "\u0000" + player.trackTitle + "\u0000" + player.length : "";

            if (trackKey !== mediaTrackKey) {
                mediaTrackKey = trackKey;
                mediaPosition = player ? player.position : 0;
            } else if (player) {
                mediaPosition = player.isPlaying
                    ? Math.min(player.length, mediaPosition + 1) : player.position;
            }
        }

        screen: modelData
        visible: root.monitors.backgroundClockVisible(monitorDescription)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "ndro-shell-desktop-widgets"
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {}

        Config.Theme {
            id: theme
        }

        Timer {
            interval: 1000
            running: widgetWindow.visible
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                widgetWindow.currentTime = new Date();
                widgetWindow.updateMediaPosition();
            }
        }

        Timer {
            interval: 900000
            running: widgetWindow.visible && root.appearance.desktopWeatherEnabled
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!weatherQuery.running)
                    weatherQuery.running = true;
            }
        }

        Process {
            id: weatherQuery

            command: ["curl", "-fsSL", "--max-time", "5",
                "https://wttr.in/" + encodeURIComponent(root.appearance.desktopWeatherLocation)
                    + "?format=%C+%t"]
            stdout: SplitParser {
                onRead: data => widgetWindow.weather = data.trim() || "Weather unavailable"
            }
            onExited: (exitCode, exitStatus) => {
                if (exitCode !== 0)
                    widgetWindow.weather = "Weather unavailable";
            }
        }

        DesktopCard {
            widget: "media"
            width: 290
            height: 74
            position: root.appearance.desktopMediaPosition
            active: root.appearance.desktopMediaEnabled && widgetWindow.player !== null

            Row {
                anchors.fill: parent
                anchors.margins: 10
                anchors.bottomMargin: 20
                spacing: 9

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: widgetWindow.player && widgetWindow.player.isPlaying ? "󰏤" : "󰐊"
                    color: theme.green
                    font.pixelSize: 19

                    TapHandler {
                        enabled: !!widgetWindow.player && widgetWindow.player.canTogglePlaying
                        onTapped: widgetWindow.player.togglePlaying()
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 38
                    spacing: 2

                    Text {
                        width: parent.width
                        text: widgetWindow.player ? widgetWindow.player.trackTitle : ""
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: widgetWindow.player ? widgetWindow.player.trackArtist : ""
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                height: 4
                radius: height / 2
                color: theme.backgroundSecondary
                visible: widgetWindow.player && widgetWindow.player.lengthSupported
                    && widgetWindow.player.length > 0

                Rectangle {
                    width: parent.width * Math.min(1, Math.max(0,
                        widgetWindow.player && widgetWindow.player.length > 0
                            ? widgetWindow.mediaPosition / widgetWindow.player.length : 0))
                    height: parent.height
                    radius: parent.radius
                    color: theme.green
                }
            }
        }

        DesktopCard {
            widget: "system"
            width: 178
            height: 96
            position: root.appearance.desktopSystemPosition
            active: root.appearance.desktopSystemEnabled

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    text: "SYSTEM"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                Text {
                    text: "󰻠  CPU  " + Math.round(root.systemMonitor.cpuUsage) + "%"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 2
                }

                Text {
                    text: "󰍛  RAM  " + Math.round(root.systemMonitor.memoryUsage) + "%"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 2
                }

                Text {
                    text: "󰔏  " + Math.round(root.systemMonitor.temperature) + "°C"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 2
                }
            }
        }

        DesktopCard {
            widget: "calendar"
            width: 204
            height: 74
            position: root.appearance.desktopCalendarPosition
            active: root.appearance.desktopCalendarEnabled

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(widgetWindow.currentTime, "dddd").toUpperCase()
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(widgetWindow.currentTime, "MMMM d")
                    color: theme.text
                    font.pixelSize: root.appearance.textSize + 3
                    font.bold: true
                }
            }
        }

        DesktopCard {
            widget: "network"
            width: 206
            height: 72
            position: root.appearance.desktopNetworkPosition
            active: root.appearance.desktopNetworkEnabled

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    width: parent.width
                    text: widgetWindow.wifi && widgetWindow.wifi.connected ? "󰤨  CONNECTED" : "󰤮  NETWORK"
                    color: widgetWindow.wifi && widgetWindow.wifi.connected ? theme.purple : theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                Text {
                    text: "󰇚  " + root.systemMonitor.formatRate(root.systemMonitor.networkDownloadRate)
                        + "    󰕒  " + root.systemMonitor.formatRate(root.systemMonitor.networkUploadRate)
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 3
                }
            }
        }

        DesktopCard {
            widget: "weather"
            width: 222
            height: 62
            position: root.appearance.desktopWeatherPosition
            active: root.appearance.desktopWeatherEnabled

            Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.appearance.desktopWeatherLocation.toUpperCase()
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 4
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: widgetWindow.weather
                    color: theme.text
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }
            }
        }
    }
}
