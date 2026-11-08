import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../bar" as Bar
import "../../config" as Config
import "../../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var systemMonitor
    // The shell's shared cava (services/Cava.qml).
    required property var cava

    model: Quickshell.screens

    readonly property int widgetGap: 10

    // `desktop` is the desktop widgets configuration of one monitor.
    function widgetEnabled(desktop, widget) {
        if (!desktop)
            return false;
        if (widget === "media")
            return desktop.media.enabled && Mpris.players.values.length > 0;
        return desktop[widget].enabled;
    }

    function widgetHeight(desktop, widget) {
        if (widget === "cava")
            return desktop.cava.height;
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

    function stackOffset(desktop, position, widget) {
        if (!desktop)
            return 0;
        const widgetOrder = DesktopWidgetsModel.desktopWidgetOrder(desktop);
        let offset = 0;

        for (let index = 0; index < widgetOrder.length; index++) {
            const candidate = widgetOrder[index];
            if (candidate === widget)
                break;
            if (widgetEnabled(desktop, candidate) && desktop[candidate].position === position)
                offset += widgetHeight(desktop, candidate) + widgetGap;
        }

        return offset;
    }

    function stackHeight(desktop, position) {
        if (!desktop)
            return 0;
        const widgetOrder = DesktopWidgetsModel.desktopWidgetOrder(desktop);
        let height = 0;

        for (let index = 0; index < widgetOrder.length; index++) {
            const widget = widgetOrder[index];
            if (widgetEnabled(desktop, widget) && desktop[widget].position === position)
                height += widgetHeight(desktop, widget) + (height > 0 ? widgetGap : 0);
        }

        return height;
    }

    component DesktopCard: Rectangle {
        required property string widget
        property var desktop: DesktopWidgetsModel.desktopWidgetsFor({}, "")
        readonly property string position: desktop ? desktop[widget].position : "center"
        property bool active: !!desktop && desktop[widget].enabled

        visible: active
        radius: root.appearance.radius
        color: Qt.rgba(cardTheme.surface.r, cardTheme.surface.g, cardTheme.surface.b, 0.70)
        border.color: cardTheme.border
        border.width: 1
        readonly property var placed: DesktopWidgetsModel.cardPosition(position,
            { width: width, height: height },
            { width: parent.width, height: parent.height },
            { offset: root.stackOffset(desktop, position, widget),
                height: root.stackHeight(desktop, position) })

        x: placed.x
        y: placed.y

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
        readonly property var desktop: root.monitors.desktopWidgetsFor(monitorDescription)
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
        color: "transparent"
        // Normal: the window fills what the monitor's bar leaves free.
        exclusionMode: ExclusionMode.Normal
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
            running: widgetWindow.visible && widgetWindow.desktop.weather.enabled
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
                "https://wttr.in/" + encodeURIComponent(widgetWindow.desktop.weather.location)
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
            desktop: widgetWindow.desktop
            active: !!desktop && desktop.media.enabled && widgetWindow.player !== null

            Row {
                anchors.fill: parent
                anchors.margins: 10
                anchors.bottomMargin: 20
                spacing: 9

                ShellText {
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

                    ShellText {
                        width: parent.width
                        text: widgetWindow.player ? widgetWindow.player.trackTitle : ""
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize
                        font.bold: true
                    }

                    ShellText {
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
            desktop: widgetWindow.desktop

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                ShellText {
                    text: "SYSTEM"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                ShellText {
                    text: "󰻠  CPU  " + Math.round(root.systemMonitor.cpuUsage) + "%"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 2
                }

                ShellText {
                    text: "󰍛  RAM  " + Math.round(root.systemMonitor.memoryUsage) + "%"
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 2
                }

                ShellText {
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
            desktop: widgetWindow.desktop

            Column {
                anchors.centerIn: parent
                spacing: 4

                ShellText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(widgetWindow.currentTime, "dddd").toUpperCase()
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                ShellText {
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
            desktop: widgetWindow.desktop

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                ShellText {
                    width: parent.width
                    text: widgetWindow.wifi && widgetWindow.wifi.connected ? "󰤨  CONNECTED" : "󰤮  NETWORK"
                    color: widgetWindow.wifi && widgetWindow.wifi.connected ? theme.purple : theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                ShellText {
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
            desktop: widgetWindow.desktop

            Column {
                anchors.centerIn: parent
                spacing: 3

                ShellText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: widgetWindow.desktop.weather.location.toUpperCase()
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 4
                    font.bold: true
                }

                ShellText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: widgetWindow.weather
                    color: theme.text
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }
            }
        }

        // Just the bars, on the wallpaper: no card behind them. They fade out
        // while cava is silent and back in with sound.
        DesktopCard {
            id: cavaWidget

            readonly property var options: widgetWindow.desktop.cava
            // While shown, it keeps the shared cava running with at least its
            // bar count; faded out in silence still counts, so cava hears the
            // sound that shows it again.
            readonly property bool drawing: active && widgetWindow.visible
            readonly property int barCount: options.barCount

            widget: "cava"
            width: options.width
            height: options.height
            desktop: widgetWindow.desktop
            color: "transparent"
            border.width: 0

            onDrawingChanged: root.cava.setDrawing(cavaWidget, drawing)
            Component.onCompleted: root.cava.setDrawing(cavaWidget, drawing)
            Component.onDestruction: root.cava.setDrawing(cavaWidget, false)

            Bar.CavaBars {
                anchors.fill: parent
                opacity: root.cava.silent ? 0 : 1
                frame: root.cava.heights
                barCount: cavaWidget.barCount
                gap: 2
                barWidth: Math.max(1, (width - gap * (barCount - 1)) / Math.max(1, barCount))
                colorName: cavaWidget.options.color
                smoothing: root.appearance.motion.frame
                layer.enabled: cavaWidget.options.shadow
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 2
                    autoPaddingEnabled: true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.appearance.motion.long
                        easing.type: root.appearance.motion.easing
                    }
                }
            }
        }
    }
}
