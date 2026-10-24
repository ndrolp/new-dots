import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "../VolumeText.js" as VolumeText

// The bar elements that need no component of their own (notifications,
// recording, media, audio, bluetooth, tray, network, battery and clock),
// placed by the bar's single walk per zone (see BarContent).
Item {
    id: root

    required property var appearance
    required property var monitorScreen
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    property string activePopup: ""
    // Where each element goes, provided by the bar's single walk per zone.
    property var elementX: element => 0
    // Whether an element sits in a group, provided by the bar's walk.
    property var elementGrouped: element => false
    signal popupRequested(string popup)
    signal notificationRequested()

    readonly property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio : null
    readonly property real volumeLevel: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio.volume : 0
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property real mediaTitleMaximumWidth: monitorScreen
        ? Math.max(96, Math.min(260, monitorScreen.width * 0.12)) : 260
    property var player: null
    readonly property string playerLabel: player
        ? (player.trackTitle !== "" ? player.trackTitle : player.identity) : ""
    property string displayedPlayerLabel: playerLabel
    readonly property real itemHeight: appearance.barTransparent
        ? appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
        : Math.max(1, appearance.barHeight - (appearance.elementVerticalPadding * 2))

    height: itemHeight
    implicitHeight: itemHeight

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

    // The item of each bar element drawn here, by element id.
    readonly property var items: ({
        "notifications": notificationButton,
        "recording": recordingButton,
        "media": mediaButton,
        "audio": audioButton,
        "bluetooth": bluetoothButton,
        "tray": trayButton,
        "network": networkButton,
        "battery": batteryButton,
        "clock": pomodoroButton
    })

    // Enabled elements with nothing to show (no player, battery or
    // recording) are hidden.
    function itemVisible(element) {
        if (!BarProfileModel.elementEnabled(appearance.barElements, element))
            return false;
        if (element === "media")
            return player !== null;
        if (element === "battery")
            return hasBattery;
        if (element === "recording")
            return screenCapture.recording;
        return true;
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
        id: notificationButton

        visible: root.itemVisible("notifications")
        x: root.elementX("notifications")
        width: notificationContent.implicitWidth + 16
        height: root.itemHeight
        radius: root.appearance.radius
        color: notificationHover.hovered ? theme.surfaceHover
            : root.elementGrouped("notifications") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted
                ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("notifications") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: notificationHover
        }

        Row {
            id: notificationContent

            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.appearance.doNotDisturb ? "󰂛" : "󰂚"
                color: root.appearance.doNotDisturb ? theme.yellow
                    : root.notificationHistory.unreadCount > 0 ? theme.accent : theme.textMuted
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: BarProfileModel.elementOption(root.appearance.barElements, "notifications", "badgeVisible")
                    && root.notificationHistory.unreadCount > 0
                text: root.notificationHistory.unreadCount > 99 ? "99+"
                    : root.notificationHistory.unreadCount
                color: root.appearance.doNotDisturb ? theme.yellow : theme.accent
                font.pixelSize: root.appearance.textSize - 2
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.notificationRequested()
        }
    }

    Rectangle {
        id: recordingButton

        visible: root.itemVisible("recording")
        x: root.elementX("recording")
        width: recordingContent.implicitWidth + 16
        height: root.itemHeight
        radius: root.appearance.radius
        color: recordingHover.hovered ? theme.surfaceHover
            : root.elementGrouped("recording") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted
                ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("recording") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: recordingHover
        }

        Row {
            id: recordingContent

            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰑋"
                color: theme.red
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "REC"
                color: theme.red
                font.pixelSize: root.appearance.textSize - 2
                font.bold: true
            }
        }

        TapHandler {
            onTapped: root.screenCapture.stopRecording()
        }
    }

    Rectangle {
        id: mediaButton

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("media") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"
        visible: root.itemVisible("media")
        x: root.elementX("media")
        width: mediaContent.implicitWidth + 16
        height: root.itemHeight
        radius: root.appearance.radius
        color: mediaHover.hovered ? theme.surfaceHover
            : root.elementGrouped("media") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface


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
                visible: BarProfileModel.elementOption(root.appearance.barElements, "media", "titleVisible")
                width: Math.min(root.mediaTitleMaximumWidth, implicitWidth)
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
        id: audioButton

        visible: root.itemVisible("audio")
        x: root.elementX("audio")
        width: 76
        height: root.itemHeight
        radius: root.appearance.radius
        color: audioHover.hovered ? theme.surfaceHover
            : root.elementGrouped("audio") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("audio") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
                visible: BarProfileModel.elementOption(root.appearance.barElements, "audio", "meterVisible")
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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !BarProfileModel.elementOption(root.appearance.barElements, "audio", "meterVisible")
                text: VolumeText.percentage(root.volumeLevel)
                color: !root.audio || root.audio.muted ? theme.textMuted : theme.blue
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("audio")
        }
    }

    Rectangle {
        id: bluetoothButton

        visible: root.itemVisible("bluetooth")
        x: root.elementX("bluetooth")
        width: root.appearance.workspaceButtonSize
        height: root.itemHeight
        radius: root.appearance.radius
        color: bluetoothHover.hovered ? theme.surfaceHover
            : root.elementGrouped("bluetooth") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("bluetooth") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
        id: trayButton

        visible: root.itemVisible("tray")
        x: root.elementX("tray")
        width: root.appearance.workspaceButtonSize
        height: root.itemHeight
        radius: root.appearance.radius
        color: trayHover.hovered ? theme.surfaceHover
            : root.elementGrouped("tray") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("tray") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
        id: networkButton

        visible: root.itemVisible("network")
        x: root.elementX("network")
        width: root.appearance.workspaceButtonSize
        height: root.itemHeight
        radius: root.appearance.radius
        color: networkHover.hovered ? theme.surfaceHover
            : root.elementGrouped("network") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("network") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
        id: batteryButton

        visible: root.itemVisible("battery")
        x: root.elementX("battery")
        width: batteryContent.implicitWidth + 16
        height: root.itemHeight
        radius: root.appearance.radius
        color: batteryHover.hovered ? theme.surfaceHover
            : root.elementGrouped("battery") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("battery") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
                visible: BarProfileModel.elementOption(root.appearance.barElements, "battery", "percentageVisible")
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
        id: pomodoroButton

        visible: root.itemVisible("clock")
        x: root.elementX("clock")
        width: clockContent.implicitWidth + 16
        height: root.itemHeight
        radius: root.appearance.radius
        color: clockHover.hovered ? theme.surfaceHover
            : root.elementGrouped("clock") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.elementGrouped("clock") ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: clockHover
        }

        Row {
            id: clockContent

            anchors.centerIn: parent
            spacing: 7

            Item {
                id: pomodoroIndicator

                width: root.pomodoro.started ? pomodoroText.implicitWidth : 0
                height: pomodoroText.implicitHeight
                clip: true

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    id: pomodoroText

                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰔟  " + root.pomodoro.remainingLabel
                    color: root.pomodoro.running ? theme.green : theme.textMuted
                    opacity: root.pomodoro.started ? 1 : 0
                    font.pixelSize: root.appearance.textSize
                    font.bold: true

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Clock {
                color: theme.orange
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested("pomodoro")
        }
    }
}
