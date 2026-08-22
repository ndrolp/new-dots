import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config

Row {
    id: root

    required property var appearance
    property string activePopup: ""
    signal popupRequested(string popup)

    readonly property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio : null
    readonly property real volumeLevel: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio.volume : 0
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    property var player: null
    readonly property string playerLabel: player
        ? (player.trackTitle !== "" ? player.trackTitle : player.identity) : ""
    property string displayedPlayerLabel: playerLabel

    spacing: appearance.spacing

    Config.Theme {
        id: theme
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    function activePlayer() {
        const players = Mpris.players.values;

        for (let index = 0; index < players.length; index++) {
            if (players[index].isPlaying)
                return players[index];
        }

        return players.length > 0 ? players[0] : null;
    }

    function updatePlayer() {
        player = activePlayer();
    }

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    onPlayerLabelChanged: mediaLabelTransition.restart()

    function networkIcon() {
        const devices = Networking.devices.values;

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];

            if (device.connected)
                return DeviceType.toString(device.type) === "Wifi" ? "󰤨" : "󰈀";
        }

        return "󰤭";
    }

    function batteryIcon() {
        if (!battery)
            return "󰂑";
        if (battery.state === UPowerDeviceState.Charging
                || battery.state === UPowerDeviceState.PendingCharge)
            return "󰂄";
        if (battery.percentage <= 0.15)
            return "󰂃";
        if (battery.percentage <= 0.4)
            return "󰁻";
        if (battery.percentage <= 0.7)
            return "󰁾";
        return "󰁹";
    }

    Rectangle {
        visible: root.player !== null
        width: mediaContent.implicitWidth + 16
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: mediaHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: mediaHover
        }

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: mediaContent

            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰎈"
                color: theme.green
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Text {
                id: mediaTitle

                property string displayedLabel: root.displayedPlayerLabel

                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(260, implicitWidth)
                text: displayedLabel
                color: theme.green
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize
                font.bold: true

                transform: Translate {
                    id: mediaLabelTranslation
                }
            }

            SequentialAnimation {
                id: mediaLabelTransition

                NumberAnimation {
                    target: mediaLabelTranslation
                    property: "x"
                    to: -12
                    duration: 90
                }

                ScriptAction {
                    script: {
                        root.displayedPlayerLabel = root.playerLabel;
                        mediaLabelTranslation.x = 12;
                    }
                }

                NumberAnimation {
                    target: mediaLabelTranslation
                    property: "x"
                    to: 0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("media")
        }
    }

    Rectangle {
        width: 76
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: audioHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: audioHover
        }

        Row {
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: !root.audio || root.audio.muted ? "󰝟" : "󰕾"
                color: theme.blue
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 4
                radius: 2
                color: theme.surface

                Rectangle {
                    width: parent.width * (root.audio && !root.audio.muted ? root.volumeLevel : 0)
                    height: parent.height
                    radius: parent.radius
                    color: theme.blue
                }

            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("audio")
        }
    }

    Rectangle {
        width: root.appearance.workspaceButtonSize
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: bluetoothHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: bluetoothHover
        }

        Text {
            anchors.centerIn: parent
            text: root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "󰂯" : "󰂲"
            color: theme.blue
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("bluetooth")
        }
    }

    Rectangle {
        width: root.appearance.workspaceButtonSize
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: trayHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: trayHover
        }

        Text {
            anchors.centerIn: parent
            text: root.activePopup === "tray" ? "󰄝" : "󰄠"
            color: theme.green
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("tray")
        }
    }

    Rectangle {
        width: root.appearance.workspaceButtonSize
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: networkHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: networkHover
        }

        Text {
            anchors.centerIn: parent
            text: root.networkIcon()
            color: theme.purple
            font.pixelSize: root.appearance.textSize
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("network")
        }
    }

    Rectangle {
        visible: root.hasBattery
        width: batteryContent.implicitWidth + 16
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: batteryHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: batteryHover
        }

        Row {
            id: batteryContent

            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryIcon()
                color: theme.yellow
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.battery.percentage * 100) + "%"
                color: theme.yellow
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("battery")
        }
    }

    Rectangle {
        width: clock.implicitWidth + 16
        height: root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
        radius: root.appearance.radius
        color: clockHover.hovered ? theme.surfaceHover : root.appearance.pillsTransparent ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: clockHover
        }

        Clock {
            id: clock

            anchors.centerIn: parent
            color: theme.orange
        }
    }
}
