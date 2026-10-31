import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config
import "." as Panels
import "../VolumeText.js" as VolumeText
import "../../config/ControlCenterTiles.js" as ControlCenterTiles
import "ControlCenterNames.js" as Names

// The control center's controls: the tiles, the sliders (volume,
// brightness, night light's temperature) and the system stats; the media
// card is not here but with the ongoing notifications above. The tiles
// come from the stored list (`barAppearance.controlCenterTiles`, see
// config/ControlCenterTiles.js): collapsed, only the first 6 visible
// tiles show, as icons; expanded, every visible tile with its label, the
// pencil that edits the list and the rest of the controls. Kept apart from
// any window: the host places it and closes it when asked.
Column {
    id: body

    // The bar it is shown from, as its popups see it (with the global
    // `doNotDisturb`).
    required property var barAppearance
    // What the tiles read (clipboardHistory, screenCapture, systemMonitor,
    // keepAwake, nightLight) and ask for (toggleDoNotDisturb, openPanel):
    // the control center module, handed down by the popup.
    required property var controlCenter
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
    property real volume: audio && !audio.muted ? audio.volume : 0
    property real brightness: 0.7
    property bool capsLocked: false
    property string powerProfile: "balanced"

    signal closeRequested()
    // The audio output tile: the host opens the audio output subpage.
    signal audioOutputsRequested()

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
            onTriggered: body.controlCenter.toggleDoNotDisturb()
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
            label: body.controlCenter.keepAwake.on ? "Awake" : "Sleep allowed"
            icon: "󰒲"
            accentColor: theme.green
            active: body.controlCenter.keepAwake.on
            onTriggered: body.controlCenter.keepAwake.toggle()
        }
    }

    Component {
        id: nightLightTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.controlCenter.nightLight.on ? "Night light" : "Night light off"
            icon: "󰖔"
            accentColor: theme.orange
            active: body.controlCenter.nightLight.on
            onTriggered: body.controlCenter.nightLight.toggle()
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
            // Opens the audio output subpage; the control center stays open.
            onTriggered: body.audioOutputsRequested()
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
            label: body.controlCenter.screenCapture.recording ? "Recording" : "Capture"
            icon: body.controlCenter.screenCapture.recording ? "󰑋" : "󰄀"
            accentColor: body.controlCenter.screenCapture.recording ? theme.red : theme.orange
            active: body.controlCenter.screenCapture.recording
            onTriggered: body.controlCenter.openPanel(Names.controlCenter.screenCapture)
        }
    }

    Component {
        id: clipboardTile

        ControlTile {
            labelShown: body.expanded
            appearance: body.barAppearance
            label: body.controlCenter.clipboardHistory.entries.length + " copied"
            icon: "󰅌"
            accentColor: theme.accent
            onTriggered: body.controlCenter.openPanel(Names.controlCenter.clipboard)
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
            onTriggered: body.controlCenter.openPanel(Names.controlCenter.powerMenu)
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
            onActivated: body.controlCenter.openPanel(Names.controlCenter.tileSettings)
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
            valueText: body.controlCenter.nightLight.temperature + " K"
            from: body.controlCenter.nightLight.minTemperature
            to: body.controlCenter.nightLight.maxTemperature
            value: body.controlCenter.nightLight.temperature
            onAdjusted: position => body.controlCenter.nightLight.setTemperature(position)
        }

        PopupLabel {
            width: parent.width
            visible: text !== ""
            appearance: body.barAppearance
            text: body.controlCenter.nightLight.failureHint
            wrapMode: Text.Wrap
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
                { label: "Uptime", value: body.controlCenter.systemMonitor.formatUptime(),
                    icon: "󰅐", color: theme.blue },
                { label: "Disk", value: body.controlCenter.systemMonitor.diskTotalGiB > 0
                    ? body.controlCenter.systemMonitor.diskUsedGiB.toFixed(0) + " / "
                        + body.controlCenter.systemMonitor.diskTotalGiB.toFixed(0) + " GiB" : "--",
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
