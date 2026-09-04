import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var clipboardHistory
    required property var screenCapture
    required property var systemMonitor
    property bool open: false
    property bool idleInhibited: false

    signal closeRequested()
    signal audioSinksRequested()
    signal clipboardRequested()
    signal powerMenuRequested()
    signal screenCaptureRequested()

    model: Quickshell.screens

    component UtilityButton: Rectangle {
        required property string label
        required property string icon
        required property color accentColor
        property bool controlEnabled: true

        signal triggered()

        radius: root.appearance.radius
        color: utilityHover.hovered && controlEnabled ? utilityTheme.surfaceHover : "transparent"
        border.color: utilityTheme.border
        border.width: 1
        opacity: controlEnabled ? 1 : 0.45

        Config.Theme {
            id: utilityTheme
        }

        HoverHandler {
            id: utilityHover
            enabled: parent.controlEnabled
        }

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.icon
                color: parent.parent.accentColor
                font.pixelSize: 15
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.parent.label
                color: utilityTheme.text
                font.pixelSize: root.appearance.textSize - 5
                font.bold: true
            }
        }

        TapHandler {
            enabled: parent.controlEnabled
            onTapped: parent.triggered()
        }
    }

    delegate: PanelWindow {
        id: controlCenter

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property var audio: Pipewire.defaultAudioSink?.audio || null
        readonly property var microphone: Pipewire.defaultAudioSource?.audio || null
        readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
        readonly property var battery: UPower.displayDevice
        readonly property var player: Mpris.players.values.find(candidate => candidate.isPlaying)
            || (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)
        property real volume: audio && !audio.muted ? audio.volume : 0
        property real brightness: 0.7
        property bool capsLocked: false
        property string powerProfile: "balanced"

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-control-center"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Config.Theme {
            id: theme
        }

        Process {
            id: volumeCommand
        }

        Process {
            id: brightnessCommand
        }

        Process {
            id: brightnessQuery

            command: ["sh", "-c", "brightnessctl -m | cut -d, -f4"]
            stdout: SplitParser {
                onRead: data => {
                    const match = data.match(/(\d+(?:\.\d+)?)%/);
                    if (match)
                        controlCenter.brightness = Number(match[1]) / 100;
                }
            }
        }

        Process {
            id: capsQuery

            command: ["sh", "-c",
                "hyprctl devices -j | jq -r '[.keyboards[].capsLock] | any'"]
            stdout: SplitParser {
                onRead: data => controlCenter.capsLocked = data.trim() === "true"
            }
        }

        Process {
            id: powerProfileQuery

            command: ["powerprofilesctl", "get"]
            stdout: SplitParser {
                onRead: data => controlCenter.powerProfile = data.trim()
            }
        }

        Process {
            id: powerProfileCommand
        }

        Timer {
            interval: 1000
            running: controlCenter.visible
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!capsQuery.running)
                    capsQuery.running = true;
            }
        }

        function close() {
            root.closeRequested();
        }

        function setVolume(value) {
            volumeCommand.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
                Math.round(Math.max(0, Math.min(1, value)) * 100) + "%"];
            volumeCommand.running = true;
        }

        function setBrightness(value) {
            brightnessCommand.command = ["brightnessctl", "set",
                Math.round(Math.max(1, Math.min(100, value * 100))) + "%"];
            brightnessCommand.running = true;
        }

        function toggleMicrophone() {
            volumeCommand.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
            volumeCommand.running = true;
        }

        function cyclePowerProfile() {
            const profiles = ["power-saver", "balanced", "performance"];
            const index = profiles.indexOf(powerProfile);
            powerProfile = profiles[(index + 1) % profiles.length];
            powerProfileCommand.command = ["powerprofilesctl", "set", powerProfile];
            powerProfileCommand.running = true;
        }

        onVisibleChanged: {
            if (visible) {
                keyboardFocus.forceActiveFocus();
                brightnessQuery.running = true;
                powerProfileQuery.running = true;
                root.clipboardHistory.refresh();
            }
        }

        IdleInhibitor {
            window: controlCenter
            enabled: root.idleInhibited
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                onClicked: controlCenter.close()
            }
        }

        Item {
            id: keyboardFocus

            anchors.fill: parent
            focus: controlCenter.visible
            Keys.onEscapePressed: controlCenter.close()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 540)
            height: content.implicitHeight + 24
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.9)
            border.color: theme.border
            border.width: 1

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Row {
                    width: parent.width

                    Text {
                        text: "Controls"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: true
                    }

                    Item {
                        width: parent.width - parent.children[0].implicitWidth - dndToggle.width
                        height: 1
                    }

                    Rectangle {
                        id: dndToggle

                        width: 72
                        height: 24
                        radius: root.appearance.radius
                        color: root.appearance.doNotDisturb ? theme.accent : theme.backgroundSecondary
                        border.color: theme.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.appearance.doNotDisturb ? "󰂛  DND" : "󰂚  DND"
                            color: root.appearance.doNotDisturb ? theme.background : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 3
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: root.appearance.doNotDisturb = !root.appearance.doNotDisturb
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: 68
                        radius: root.appearance.radius
                        color: "transparent"
                        border.color: theme.border
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Row {
                                width: parent.width
                                height: 18

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰕾  Volume"
                                    color: theme.blue
                                    font.pixelSize: root.appearance.textSize - 1
                                    font.bold: true
                                }

                                Item {
                                    width: parent.width - parent.children[0].implicitWidth - volumeLabel.implicitWidth
                                    height: 1
                                }

                                Text {
                                    id: volumeLabel

                                    anchors.verticalCenter: parent.verticalCenter
                                    text: controlCenter.audio && !controlCenter.audio.muted
                                        ? Math.round(controlCenter.audio.volume * 100) + "%" : "Muted"
                                    color: theme.text
                                    font.pixelSize: root.appearance.textSize - 2
                                    font.bold: true
                                }
                            }

                            Slider {
                                id: volumeSlider

                                width: parent.width
                                implicitHeight: 18
                                from: 0
                                to: 1
                                value: controlCenter.volume
                                onMoved: controlCenter.setVolume(value)

                                background: Rectangle {
                                    x: volumeSlider.leftPadding
                                    y: volumeSlider.topPadding
                                        + (volumeSlider.availableHeight - height) / 2
                                    width: volumeSlider.availableWidth
                                    height: 4
                                    radius: 3
                                    color: theme.surface

                                    Rectangle {
                                        width: parent.width * volumeSlider.visualPosition
                                        height: parent.height
                                        radius: parent.radius
                                        color: theme.blue
                                    }
                                }

                                handle: Rectangle {
                                    x: volumeSlider.leftPadding + volumeSlider.visualPosition
                                        * (volumeSlider.availableWidth - width)
                                    y: volumeSlider.topPadding
                                        + (volumeSlider.availableHeight - height) / 2
                                    width: 12
                                    height: 12
                                    radius: width / 2
                                    color: theme.blue
                                    border.color: theme.surface
                                    border.width: 2
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: 68
                        radius: root.appearance.radius
                        color: "transparent"
                        border.color: theme.border
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Row {
                                width: parent.width
                                height: 18

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰃠  Brightness"
                                    color: theme.yellow
                                    font.pixelSize: root.appearance.textSize - 1
                                    font.bold: true
                                }

                                Item {
                                    width: parent.width - parent.children[0].implicitWidth
                                        - brightnessLabel.implicitWidth
                                    height: 1
                                }

                                Text {
                                    id: brightnessLabel

                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(controlCenter.brightness * 100) + "%"
                                    color: theme.text
                                    font.pixelSize: root.appearance.textSize - 2
                                    font.bold: true
                                }
                            }

                            Slider {
                                id: brightnessSlider

                                width: parent.width
                                implicitHeight: 18
                                from: 0.01
                                to: 1
                                value: controlCenter.brightness
                                onMoved: {
                                    controlCenter.brightness = value;
                                    controlCenter.setBrightness(value);
                                }

                                background: Rectangle {
                                    x: brightnessSlider.leftPadding
                                    y: brightnessSlider.topPadding
                                        + (brightnessSlider.availableHeight - height) / 2
                                    width: brightnessSlider.availableWidth
                                    height: 4
                                    radius: 3
                                    color: theme.surface

                                    Rectangle {
                                        width: parent.width * brightnessSlider.visualPosition
                                        height: parent.height
                                        radius: parent.radius
                                        color: theme.yellow
                                    }
                                }

                                handle: Rectangle {
                                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition
                                        * (brightnessSlider.availableWidth - width)
                                    y: brightnessSlider.topPadding
                                        + (brightnessSlider.availableHeight - height) / 2
                                    width: 12
                                    height: 12
                                    radius: width / 2
                                    color: theme.yellow
                                    border.color: theme.surface
                                    border.width: 2
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: [
                            { label: "Audio output", icon: "󰓃", color: theme.accent, action: "audio" },
                            { label: "Lock", icon: "󰌾", color: theme.blue, action: "lock" },
                            { label: "Displays off", icon: "󰍹", color: theme.orange, action: "display" },
                            { label: controlCenter.powerProfile, icon: "󱐋",
                                color: theme.green, action: "profile" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: (parent.width - parent.spacing * 3) / 4
                            height: 38
                            radius: root.appearance.radius
                            color: quickHover.hovered ? theme.surfaceHover : "transparent"
                            border.color: theme.border
                            border.width: 1

                            HoverHandler {
                                id: quickHover
                            }

                            Row {
                                anchors.centerIn: parent
                                height: parent.height
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    color: modelData.color
                                    font.pixelSize: 16
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: theme.text
                                    font.pixelSize: root.appearance.textSize - 4
                                    font.bold: true
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    if (modelData.action === "audio") {
                                        root.audioSinksRequested();
                                        controlCenter.close();
                                    } else if (modelData.action === "lock") {
                                        volumeCommand.command = ["loginctl", "lock-session"];
                                        volumeCommand.running = true;
                                        controlCenter.close();
                                    } else {
                                        if (modelData.action === "display") {
                                            volumeCommand.command = ["hyprctl", "dispatch", "dpms", "off"];
                                            volumeCommand.running = true;
                                            controlCenter.close();
                                        } else {
                                            controlCenter.cyclePowerProfile();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"
                        icon: "󰤨"
                        accentColor: theme.purple
                        onTriggered: Networking.wifiEnabled = !Networking.wifiEnabled
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: controlCenter.bluetoothAdapter
                            && controlCenter.bluetoothAdapter.enabled ? "Bluetooth" : "BT off"
                        icon: "󰂯"
                        accentColor: theme.blue
                        controlEnabled: controlCenter.bluetoothAdapter !== null
                        onTriggered: controlCenter.bluetoothAdapter.enabled
                            = !controlCenter.bluetoothAdapter.enabled
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: controlCenter.microphone && !controlCenter.microphone.muted
                            ? "Mic on" : "Mic off"
                        icon: "󰍬"
                        accentColor: theme.red
                        controlEnabled: controlCenter.microphone !== null
                        onTriggered: controlCenter.toggleMicrophone()
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: root.idleInhibited ? "Awake" : "Sleep allowed"
                        icon: "󰒲"
                        accentColor: theme.green
                        onTriggered: root.idleInhibited = !root.idleInhibited
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: root.screenCapture.recording ? "Recording" : "Capture"
                        icon: root.screenCapture.recording ? "󰑋" : "󰄀"
                        accentColor: root.screenCapture.recording ? theme.red : theme.orange
                        onTriggered: root.screenCaptureRequested()
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: root.clipboardHistory.entries.length + " copied"
                        icon: "󰅌"
                        accentColor: theme.accent
                        onTriggered: root.clipboardRequested()
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: "Power"
                        icon: "󰐥"
                        accentColor: theme.red
                        onTriggered: root.powerMenuRequested()
                    }

                    UtilityButton {
                        width: (parent.width - parent.spacing * 3) / 4
                        height: 38
                        label: "Caps " + (controlCenter.capsLocked ? "on" : "off")
                        icon: "󰘲"
                        accentColor: controlCenter.capsLocked ? theme.yellow : theme.textMuted
                    }
                }

                Rectangle {
                    width: parent.width
                    height: controlCenter.player ? 52 : 0
                    visible: height > 0
                    radius: root.appearance.radius
                    color: "transparent"
                    border.color: theme.border
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: controlCenter.player && controlCenter.player.isPlaying ? "󰏤" : "󰐊"
                            color: theme.green
                            font.pixelSize: 18

                            TapHandler {
                                onTapped: {
                                    if (controlCenter.player && controlCenter.player.canTogglePlaying)
                                        controlCenter.player.togglePlaying();
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 48
                            spacing: 1

                            Text {
                                width: parent.width
                                text: controlCenter.player ? controlCenter.player.trackTitle : ""
                                color: theme.text
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize
                                font.bold: true
                            }

                            Text {
                                width: parent.width
                                text: controlCenter.player ? controlCenter.player.trackArtist : ""
                                color: theme.textMuted
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize - 3
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: [
                            { label: "Battery", value: controlCenter.battery
                                ? Math.round(controlCenter.battery.percentage * 100) + "%" : "--",
                                icon: "󰁹", color: theme.green },
                            { label: "Uptime", value: root.systemMonitor.formatUptime(),
                                icon: "󰅐", color: theme.blue },
                            { label: "Disk", value: root.systemMonitor.diskTotalGiB > 0
                                ? root.systemMonitor.diskUsedGiB.toFixed(0) + " / "
                                    + root.systemMonitor.diskTotalGiB.toFixed(0) + " GiB" : "--",
                                icon: "󰋊", color: theme.purple }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: (parent.width - parent.spacing * 2) / 3
                            height: 38
                            radius: root.appearance.radius
                            color: "transparent"
                            border.color: theme.border
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 16
                                spacing: 1

                                Text {
                                    text: modelData.icon + "  " + modelData.label
                                    color: modelData.color
                                    font.pixelSize: root.appearance.textSize - 4
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.value
                                    color: theme.text
                                    font.pixelSize: root.appearance.textSize - 2
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
