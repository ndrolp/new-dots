import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config
import "." as Panels
import "../VolumeText.js" as VolumeText
import "../../config/ControlCenterTiles.js" as ControlCenterTiles

// The control center's controls: the tiles, the sliders (volume,
// brightness, night light's temperature), the media row and the system
// stats. The tiles come from the stored list (`barAppearance.controlCenterTiles`,
// see config/ControlCenterTiles.js): collapsed, only the first 6 visible
// tiles show, as icons; expanded, every visible tile with its label, the
// pencil that edits the list and the rest of the controls. Kept apart from
// any window: the host places it and closes it when asked.
Column {
    id: body

    // The bar it is shown from, as its popups see it (with the global
    // `doNotDisturb`).
    required property var barAppearance
    required property var clipboardHistory
    required property var screenCapture
    required property var systemMonitor
    required property var keepAwake
    // The shell's night light (services/NightLight.qml).
    required property var nightLight
    // Whether the host is showing it: it reads brightness, the power
    // profile and the clipboard when shown, and Caps Lock while shown (any
    // tile can sit in the collapsed row).
    property bool shown: false
    // The expanded control center: every control, not just the quick tiles.
    property bool expanded: false

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

    signal closeRequested()
    // The do not disturb tile was pressed; the shell owns the setting.
    signal doNotDisturbToggled()
    signal audioSinksRequested()
    signal clipboardRequested()
    signal powerMenuRequested()
    signal screenCaptureRequested()
    // The pencil: edit the tile list in the settings panel.
    signal tileSettingsRequested()

    spacing: 12

    Config.Theme {
        id: theme
    }

    BluetoothPower {
        id: bluetoothPower
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
                    body.brightness = Number(match[1]) / 100;
            }
        }
    }

    Process {
        id: capsQuery

        command: ["sh", "-c",
            "hyprctl devices -j | jq -r '[.keyboards[].capsLock] | any'"]
        stdout: SplitParser {
            onRead: data => body.capsLocked = data.trim() === "true"
        }
    }

    Process {
        id: powerProfileQuery

        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: data => body.powerProfile = data.trim()
        }
    }

    Process {
        id: powerProfileCommand
    }

    Timer {
        interval: 1000
        running: body.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!capsQuery.running)
                capsQuery.running = true;
        }
    }

    function close() {
        closeRequested();
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
            brightnessQuery.running = true;
            powerProfileQuery.running = true;
            clipboardHistory.refresh();
        }
    }

    // Every tile, by its id in the stored list (config/ControlCenterTiles.js).
    readonly property var tileComponents: ({
        "wifi": wifiTile,
        "bluetooth": bluetoothTile,
        "doNotDisturb": doNotDisturbTile,
        "microphone": microphoneTile,
        "keepAwake": keepAwakeTile,
        "nightLight": nightLightTile,
        "audioOutput": audioOutputTile,
        "lock": lockTile,
        "displaysOff": displaysOffTile,
        "powerProfile": powerProfileTile,
        "screenCapture": screenCaptureTile,
        "clipboard": clipboardTile,
        "power": powerTile,
        "capsLock": capsLockTile
    })

    Component {
        id: wifiTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi off"
            icon: "󰤨"
            accentColor: theme.purple
            active: Networking.wifiEnabled
            onTriggered: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Component {
        id: bluetoothTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: active ? "Bluetooth" : "BT off"
            icon: "󰂯"
            accentColor: theme.blue
            active: body.bluetoothAdapter !== null
                && body.bluetoothAdapter.enabled
            controlEnabled: body.bluetoothAdapter !== null
            onTriggered: bluetoothPower.setEnabled(!body.bluetoothAdapter.enabled)
        }
    }

    Component {
        id: doNotDisturbTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: active ? "Do not disturb" : "DND off"
            icon: "󰂛"
            accentColor: theme.purple
            active: body.barAppearance.doNotDisturb
            onTriggered: body.doNotDisturbToggled()
        }
    }

    Component {
        id: microphoneTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: active ? "Mic on" : "Mic off"
            icon: "󰍬"
            accentColor: theme.red
            active: body.microphone !== null && !body.microphone.muted
            controlEnabled: body.microphone !== null
            onTriggered: body.toggleMicrophone()
        }
    }

    Component {
        id: keepAwakeTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.keepAwake.on ? "Awake" : "Sleep allowed"
            icon: "󰒲"
            accentColor: theme.green
            active: body.keepAwake.on
            onTriggered: body.keepAwake.toggle()
        }
    }

    Component {
        id: nightLightTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.nightLight.on ? "Night light" : "Night light off"
            icon: "󰖔"
            accentColor: theme.orange
            active: body.nightLight.on
            onTriggered: body.nightLight.toggle()
        }
    }

    Component {
        id: audioOutputTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: "Audio output"
            icon: "󰓃"
            accentColor: theme.accent
            onTriggered: {
                body.audioSinksRequested();
                body.close();
            }
        }
    }

    Component {
        id: lockTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: "Lock"
            icon: "󰌾"
            accentColor: theme.blue
            onTriggered: {
                volumeCommand.command = ["loginctl", "lock-session"];
                volumeCommand.running = true;
                body.close();
            }
        }
    }

    Component {
        id: displaysOffTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: "Displays off"
            icon: "󰍹"
            accentColor: theme.orange
            onTriggered: {
                volumeCommand.command = ["hyprctl", "dispatch", "dpms", "off"];
                volumeCommand.running = true;
                body.close();
            }
        }
    }

    Component {
        id: powerProfileTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.powerProfile
            icon: "󱐋"
            accentColor: theme.green
            active: true
            onTriggered: body.cyclePowerProfile()
        }
    }

    Component {
        id: screenCaptureTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.screenCapture.recording ? "Recording" : "Capture"
            icon: body.screenCapture.recording ? "󰑋" : "󰄀"
            accentColor: body.screenCapture.recording ? theme.red : theme.orange
            active: body.screenCapture.recording
            onTriggered: body.screenCaptureRequested()
        }
    }

    Component {
        id: clipboardTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.clipboardHistory.entries.length + " copied"
            icon: "󰅌"
            accentColor: theme.accent
            onTriggered: body.clipboardRequested()
        }
    }

    Component {
        id: powerTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: "Power"
            icon: "󰐥"
            accentColor: theme.red
            onTriggered: body.powerMenuRequested()
        }
    }

    Component {
        id: capsLockTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: "Caps " + (body.capsLocked ? "on" : "off")
            icon: "󰘲"
            accentColor: theme.yellow
            active: body.capsLocked
            interactive: false
        }
    }

    // Collapsed, the first 6 visible tiles; expanded, every visible tile.
    readonly property var shownTiles: body.expanded
        ? ControlCenterTiles.visibleTiles(body.barAppearance.controlCenterTiles)
        : ControlCenterTiles.collapsedTiles(body.barAppearance.controlCenterTiles)

    Grid {
        id: tiles

        readonly property real tileWidth: (width - columnSpacing * (columns - 1)) / columns

        width: parent.width
        // The collapsed row fits one line.
        columns: body.expanded ? 4 : ControlCenterTiles.collapsedRowSize
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: body.shownTiles

            delegate: Loader {
                required property string modelData

                width: tiles.tileWidth
                sourceComponent: body.tileComponents[modelData] || null
            }
        }
    }

    // Expanded only: the pencil opens the settings panel at the Control
    // center section.
    Item {
        width: parent.width
        height: editTilesButton.height
        visible: body.expanded

        PopupButton {
            id: editTilesButton

            anchors.right: parent.right
            width: 36
            appearance: body.barAppearance
            label: "󰏫"
            onActivated: body.tileSettingsRequested()
        }
    }

    // Volume and brightness, then night light's temperature.
    Column {
        width: parent.width
        visible: body.expanded
        spacing: 12

        Row {
            width: parent.width
            spacing: 16

            ControlSlider {
                width: (parent.width - parent.spacing) / 2
                appearance: body.barAppearance
                label: "Volume"
                icon: "󰕾"
                accentColor: theme.blue
                valueText: body.audio && !body.audio.muted
                    ? VolumeText.percentage(body.audio.volume) : "Muted"
                from: 0
                to: 1
                value: body.volume
                onAdjusted: position => body.setVolume(position)
            }

            ControlSlider {
                width: (parent.width - parent.spacing) / 2
                appearance: body.barAppearance
                label: "Brightness"
                icon: "󰃠"
                accentColor: theme.yellow
                valueText: Math.round(body.brightness * 100) + "%"
                from: 0.01
                to: 1
                value: body.brightness
                onAdjusted: position => {
                    body.brightness = position;
                    body.setBrightness(position);
                }
            }
        }

        ControlSlider {
            width: parent.width
            appearance: body.barAppearance
            label: "Temperature"
            icon: "󰔏"
            accentColor: theme.orange
            valueText: body.nightLight.temperature + " K"
            from: body.nightLight.minTemperature
            to: body.nightLight.maxTemperature
            value: body.nightLight.temperature
            onAdjusted: position => body.nightLight.setTemperature(position)
        }

        PopupLabel {
            width: parent.width
            visible: text !== ""
            appearance: body.barAppearance
            text: body.nightLight.failureHint
            wrapMode: Text.Wrap
        }
    }

    PopupRow {
        width: parent.width
        height: body.expanded && body.player ? 44 : 0
        visible: height > 0
        appearance: body.barAppearance
        interactive: false

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            Panels.Text {
                anchors.verticalCenter: parent.verticalCenter
                text: body.player && body.player.isPlaying ? "󰏤" : "󰐊"
                color: theme.green
                font.pixelSize: body.barAppearance.textSize + 5

                TapHandler {
                    onTapped: {
                        if (body.player && body.player.canTogglePlaying)
                            body.player.togglePlaying();
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 48
                spacing: 1

                PopupTitle {
                    width: parent.width
                    appearance: body.barAppearance
                    text: body.player ? body.player.trackTitle : ""
                    font.pixelSize: body.barAppearance.textSize
                }

                PopupLabel {
                    width: parent.width
                    appearance: body.barAppearance
                    text: body.player ? body.player.trackArtist : ""
                }
            }
        }
    }

    Row {
        width: parent.width
        visible: body.expanded
        spacing: 10

        Repeater {
            model: [
                { label: "Battery", value: body.battery
                    ? Math.round(body.battery.percentage * 100) + "%" : "--",
                    icon: "󰁹", color: theme.green },
                { label: "Uptime", value: body.systemMonitor.formatUptime(),
                    icon: "󰅐", color: theme.blue },
                { label: "Disk", value: body.systemMonitor.diskTotalGiB > 0
                    ? body.systemMonitor.diskUsedGiB.toFixed(0) + " / "
                        + body.systemMonitor.diskTotalGiB.toFixed(0) + " GiB" : "--",
                    icon: "󰋊", color: theme.purple }
            ]

            delegate: Column {
                required property var modelData

                width: (parent.width - parent.spacing * 2) / 3
                spacing: 2

                PopupLabel {
                    width: parent.width
                    appearance: body.barAppearance
                    text: modelData.icon + "  " + modelData.label
                }

                Panels.Text {
                    width: parent.width
                    text: modelData.value
                    color: theme.text
                    elide: Text.ElideRight
                    font.pixelSize: body.barAppearance.textSize - 1
                }
            }
        }
    }
}
