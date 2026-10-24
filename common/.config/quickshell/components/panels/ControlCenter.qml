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
import "PopupPlacement.js" as PopupPlacement

// The Control center: quick toggles and sliders, centered at the top of the
// focused monitor. Decided per monitor from that bar's profile, it hangs from
// an opaque bar in the bar's color and opacity, like an attached popup, and
// floats below a transparent one.
Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
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

    // A quick toggle or action: a row with a colored icon and a label. An
    // active toggle shows it with its color; the rest stay muted until hovered.
    component ControlTile: PopupRow {
        id: tile

        required property string label
        required property string icon
        required property color accentColor
        property bool active: false
        property bool controlEnabled: true

        signal triggered()

        height: 38
        interactive: controlEnabled
        opacity: controlEnabled ? 1 : 0.45

        Config.Theme {
            id: tileTheme
        }

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tile.icon
                color: tile.active || tile.hovered ? tile.accentColor : tileTheme.textMuted
                font.pixelSize: tile.appearance.textSize + 3

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tile.label
                color: tile.active ? tileTheme.text : tileTheme.textMuted
                font.pixelSize: tile.appearance.textSize - 2
            }
        }

        TapHandler {
            enabled: tile.controlEnabled
            onTapped: tile.triggered()
        }
    }

    // A labelled slider with its value on the right.
    component ControlSlider: Column {
        id: control

        required property var appearance
        required property string label
        required property string icon
        required property color accentColor
        property string valueText: ""
        property alias from: slider.from
        property alias to: slider.to
        property alias value: slider.value

        signal adjusted(real position)

        spacing: 4

        Config.Theme {
            id: sliderTheme
        }

        Item {
            width: parent.width
            height: Math.max(sliderLabel.implicitHeight, sliderValue.implicitHeight)

            Text {
                id: sliderLabel

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: control.icon + "  " + control.label
                color: sliderTheme.text
                font.pixelSize: control.appearance.textSize - 1
            }

            PopupLabel {
                id: sliderValue

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                appearance: control.appearance
                text: control.valueText
            }
        }

        Slider {
            id: slider

            width: parent.width
            implicitHeight: 18
            onMoved: control.adjusted(value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: sliderTheme.backgroundSecondary

                Rectangle {
                    width: parent.width * slider.visualPosition
                    height: parent.height
                    radius: parent.radius
                    color: control.accentColor
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                width: 12
                height: 12
                radius: width / 2
                color: control.accentColor
            }
        }
    }

    delegate: PanelWindow {
        id: controlCenter

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        // Open on the focused monitor; the window stays up while it closes.
        readonly property bool shown: root.open && focusedMonitor
        readonly property string monitorDescription: root.workspaceService.monitorDescriptionForScreen(modelData)
        readonly property string profileName: root.monitors.barProfileFor(monitorDescription)
        // This monitor's bar, as its popups see it.
        property var barAppearance: QtObject {
            property int barHeight: root.appearance.barProfileValue(controlCenter.profileName, "barHeight")
            property int spacing: root.appearance.barProfileValue(controlCenter.profileName, "spacing")
            property int radius: root.appearance.barProfileValue(controlCenter.profileName, "radius")
            property int textSize: root.appearance.barProfileValue(controlCenter.profileName, "textSize")
            property int transparentBarTopMargin: root.appearance.barProfileValue(controlCenter.profileName, "transparentBarTopMargin")
            property bool transparentBarSlanted: root.appearance.barProfileValue(controlCenter.profileName, "transparentBarSlanted")
            property bool barTransparent: root.appearance.barProfileValue(controlCenter.profileName, "barTransparent")
            property int barOpacity: root.appearance.barProfileValue(controlCenter.profileName, "barOpacity")
        }
        // The bar window's height, as the bar computes it.
        readonly property int totalBarHeight: barAppearance.barHeight
            + (barAppearance.barTransparent && !barAppearance.transparentBarSlanted
                ? barAppearance.transparentBarTopMargin : 0)
        readonly property var placement: PopupPlacement.controlCenter({
            barVisible: root.monitors.barVisible(monitorDescription),
            barTransparent: barAppearance.barTransparent,
            barHeight: totalBarHeight,
            spacing: barAppearance.spacing
        })
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
        visible: surface.reveal > 0
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
            running: controlCenter.shown
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

        onShownChanged: {
            if (shown) {
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

        Item {
            id: keyboardFocus

            anchors.fill: parent
            focus: controlCenter.shown
            Keys.onEscapePressed: controlCenter.close()

            // A click outside the Control center closes it.
            TapHandler {
                enabled: controlCenter.shown
                onTapped: controlCenter.close()
            }
        }

        // Keeps clicks on the Control center's own background from closing it.
        MouseArea {
            x: surface.x
            y: surface.y
            width: surface.width
            height: surface.unfoldedHeight
        }

        PopupSurface {
            id: surface

            anchors.horizontalCenter: parent.horizontalCenter
            y: controlCenter.placement.y
            width: Math.min(parent.width - 48, 540)
            height: implicitHeight
            open: controlCenter.shown
            enabled: controlCenter.shown
            attached: controlCenter.placement.attached
            radius: controlCenter.barAppearance.radius
            // The bar's own color and opacity, so an attached Control center
            // looks like part of the bar.
            fillColor: attached
                ? Qt.rgba(theme.background.r, theme.background.g, theme.background.b,
                    controlCenter.barAppearance.barOpacity / 100)
                : theme.surface

            Column {
                width: parent.width
                spacing: 12

                PopupHeader {
                    appearance: controlCenter.barAppearance
                    title: "Controls"

                    Row {
                        spacing: 8

                        PopupLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            appearance: controlCenter.barAppearance
                            text: "Do not disturb"
                        }

                        PopupSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            appearance: controlCenter.barAppearance
                            checked: root.appearance.doNotDisturb
                            onToggled: root.appearance.doNotDisturb = !root.appearance.doNotDisturb
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 16

                    ControlSlider {
                        width: (parent.width - parent.spacing) / 2
                        appearance: controlCenter.barAppearance
                        label: "Volume"
                        icon: "󰕾"
                        accentColor: theme.blue
                        valueText: controlCenter.audio && !controlCenter.audio.muted
                            ? Math.round(controlCenter.audio.volume * 100) + "%" : "Muted"
                        from: 0
                        to: 1
                        value: controlCenter.volume
                        onAdjusted: position => controlCenter.setVolume(position)
                    }

                    ControlSlider {
                        width: (parent.width - parent.spacing) / 2
                        appearance: controlCenter.barAppearance
                        label: "Brightness"
                        icon: "󰃠"
                        accentColor: theme.yellow
                        valueText: Math.round(controlCenter.brightness * 100) + "%"
                        from: 0.01
                        to: 1
                        value: controlCenter.brightness
                        onAdjusted: position => {
                            controlCenter.brightness = position;
                            controlCenter.setBrightness(position);
                        }
                    }
                }

                Grid {
                    id: tiles

                    readonly property real tileWidth: (width - columnSpacing * (columns - 1)) / columns

                    width: parent.width
                    columns: 4
                    columnSpacing: 4
                    rowSpacing: 4

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: "Audio output"
                        icon: "󰓃"
                        accentColor: theme.accent
                        onTriggered: {
                            root.audioSinksRequested();
                            controlCenter.close();
                        }
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: "Lock"
                        icon: "󰌾"
                        accentColor: theme.blue
                        onTriggered: {
                            volumeCommand.command = ["loginctl", "lock-session"];
                            volumeCommand.running = true;
                            controlCenter.close();
                        }
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: "Displays off"
                        icon: "󰍹"
                        accentColor: theme.orange
                        onTriggered: {
                            volumeCommand.command = ["hyprctl", "dispatch", "dpms", "off"];
                            volumeCommand.running = true;
                            controlCenter.close();
                        }
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: controlCenter.powerProfile
                        icon: "󱐋"
                        accentColor: theme.green
                        active: true
                        onTriggered: controlCenter.cyclePowerProfile()
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"
                        icon: "󰤨"
                        accentColor: theme.purple
                        active: Networking.wifiEnabled
                        onTriggered: Networking.wifiEnabled = !Networking.wifiEnabled
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: active ? "Bluetooth" : "BT off"
                        icon: "󰂯"
                        accentColor: theme.blue
                        active: controlCenter.bluetoothAdapter !== null
                            && controlCenter.bluetoothAdapter.enabled
                        controlEnabled: controlCenter.bluetoothAdapter !== null
                        onTriggered: controlCenter.bluetoothAdapter.enabled
                            = !controlCenter.bluetoothAdapter.enabled
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: active ? "Mic on" : "Mic off"
                        icon: "󰍬"
                        accentColor: theme.red
                        active: controlCenter.microphone !== null && !controlCenter.microphone.muted
                        controlEnabled: controlCenter.microphone !== null
                        onTriggered: controlCenter.toggleMicrophone()
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: root.idleInhibited ? "Awake" : "Sleep allowed"
                        icon: "󰒲"
                        accentColor: theme.green
                        active: root.idleInhibited
                        onTriggered: root.idleInhibited = !root.idleInhibited
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: root.screenCapture.recording ? "Recording" : "Capture"
                        icon: root.screenCapture.recording ? "󰑋" : "󰄀"
                        accentColor: root.screenCapture.recording ? theme.red : theme.orange
                        active: root.screenCapture.recording
                        onTriggered: root.screenCaptureRequested()
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: root.clipboardHistory.entries.length + " copied"
                        icon: "󰅌"
                        accentColor: theme.accent
                        onTriggered: root.clipboardRequested()
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: "Power"
                        icon: "󰐥"
                        accentColor: theme.red
                        onTriggered: root.powerMenuRequested()
                    }

                    ControlTile {
                        width: tiles.tileWidth
                        appearance: controlCenter.barAppearance
                        label: "Caps " + (controlCenter.capsLocked ? "on" : "off")
                        icon: "󰘲"
                        accentColor: theme.yellow
                        active: controlCenter.capsLocked
                        interactive: false
                    }
                }

                PopupRow {
                    width: parent.width
                    height: controlCenter.player ? 44 : 0
                    visible: height > 0
                    appearance: controlCenter.barAppearance
                    interactive: false

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: controlCenter.player && controlCenter.player.isPlaying ? "󰏤" : "󰐊"
                            color: theme.green
                            font.pixelSize: controlCenter.barAppearance.textSize + 5

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

                            PopupTitle {
                                width: parent.width
                                appearance: controlCenter.barAppearance
                                text: controlCenter.player ? controlCenter.player.trackTitle : ""
                                font.pixelSize: controlCenter.barAppearance.textSize
                            }

                            PopupLabel {
                                width: parent.width
                                appearance: controlCenter.barAppearance
                                text: controlCenter.player ? controlCenter.player.trackArtist : ""
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

                        delegate: Column {
                            required property var modelData

                            width: (parent.width - parent.spacing * 2) / 3
                            spacing: 2

                            PopupLabel {
                                width: parent.width
                                appearance: controlCenter.barAppearance
                                text: modelData.icon + "  " + modelData.label
                            }

                            Text {
                                width: parent.width
                                text: modelData.value
                                color: theme.text
                                elide: Text.ElideRight
                                font.pixelSize: controlCenter.barAppearance.textSize - 1
                            }
                        }
                    }
                }
            }
        }
    }
}
