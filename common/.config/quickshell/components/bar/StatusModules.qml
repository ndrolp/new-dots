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

Item {
    id: root

    required property var appearance
    required property var monitorScreen
    required property var pomodoro
    required property var notificationHistory
    required property var screenCapture
    property string activePopup: ""
    // Where each module goes, provided by the bar's single walk per zone.
    property var elementX: module => 0
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
    readonly property var moduleOrder: [
        "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
        "battery", "clock"
    ]
    readonly property real moduleHeight: appearance.barTransparent || appearance.statusIsland
        ? appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
        : Math.max(1, appearance.barHeight - (appearance.structuralVerticalPadding * 2))

    height: moduleHeight
    implicitHeight: moduleHeight

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

    function popupTrigger(popup) {
        if (popup === "media")
            return mediaButton;
        if (popup === "audio")
            return audioButton;
        if (popup === "bluetooth")
            return bluetoothButton;
        if (popup === "tray")
            return trayButton;
        if (popup === "network")
            return networkButton;
        if (popup === "battery")
            return batteryButton;
        if (popup === "pomodoro")
            return pomodoroButton;
        return null;
    }

    function moduleItem(module) {
        if (module === "notifications")
            return notificationButton;
        if (module === "recording")
            return recordingButton;
        if (module === "clock")
            return pomodoroButton;
        return popupTrigger(module);
    }

    function moduleZone(module) {
        return BarProfileModel.elementZone(appearance.barElements, module);
    }

    function moduleVisible(module) {
        if (!BarProfileModel.elementEnabled(appearance.barElements, module))
            return false;
        if (module === "media")
            return player !== null;
        if (module === "battery")
            return hasBattery;
        if (module === "recording")
            return screenCapture.recording;
        return true;
    }

    function moduleWidth(module) {
        if (module === "notifications")
            return notificationButton.width;
        if (module === "recording")
            return recordingButton.width;
        if (module === "media")
            return mediaButton.width;
        if (module === "audio")
            return audioButton.width;
        if (module === "bluetooth")
            return bluetoothButton.width;
        if (module === "tray")
            return trayButton.width;
        if (module === "network")
            return networkButton.width;
        if (module === "battery")
            return batteryButton.width;
        return pomodoroButton.width;
    }

    function moduleGroup(module) {
        return (appearance.statusModuleGroups || {})[module] || 0;
    }

    function isGrouped(module) {
        const group = moduleGroup(module);

        if (group === 0)
            return false;

        let count = 0;
        for (let index = 0; index < moduleOrder.length; index++) {
            const candidate = moduleOrder[index];
            if (moduleVisible(candidate) && moduleGroup(candidate) === group
                    && moduleZone(candidate) === moduleZone(module))
                count++;
        }

        return count > 1;
    }

    // Gap between two adjacent bar elements of a zone: modules of one group
    // sit close together.
    function moduleGap(previousModule, module) {
        const modules = moduleOrder.indexOf(previousModule) !== -1
            && moduleOrder.indexOf(module) !== -1;
        return modules && isGrouped(previousModule) && isGrouped(module)
            && moduleGroup(previousModule) === moduleGroup(module) ? 2 : appearance.spacing;
    }

    function moduleX(module) {
        return elementX(module);
    }

    // Extent of a numbered group within one zone; a group split across zones
    // gets one background per zone.
    function groupExtent(group, zone) {
        let start = -1;
        let end = 0;

        for (let index = 0; index < moduleOrder.length; index++) {
            const module = moduleOrder[index];
            if (moduleVisible(module) && moduleGroup(module) === group && moduleZone(module) === zone) {
                const x = moduleX(module);
                start = start === -1 ? x : Math.min(start, x);
                end = Math.max(end, x + moduleWidth(module));
            }
        }

        return start === -1 ? { x: 0, width: 0 } : { x: start - 5, width: end - start + 10 };
    }

    Component.onCompleted: updatePlayer()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updatePlayer()
    }

    onPlayerLabelChanged: mediaLabelTransition.restart()

    Repeater {
        model: {
            const extents = [];
            for (const group of [1, 2, 3]) {
                for (const zone of ["left", "center", "right"])
                    extents.push({ group: group, zone: zone });
            }
            return extents;
        }

        delegate: Rectangle {
            required property var modelData
            readonly property var extent: root.groupExtent(modelData.group, modelData.zone)

            x: extent.x
            anchors.verticalCenter: parent.verticalCenter
            width: extent.width
            height: root.moduleHeight
            radius: root.appearance.radius
            color: theme.surface
            visible: extent.width > 0
            z: -1
        }
    }

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

        visible: root.moduleVisible("notifications")
        x: root.moduleX("notifications")
        width: notificationContent.implicitWidth + 16
        height: root.moduleHeight
        radius: root.appearance.radius
        color: notificationHover.hovered ? theme.surfaceHover
            : root.isGrouped("notifications") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted || root.appearance.statusIsland
                ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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
                visible: root.appearance.notificationBadgeVisible !== false
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

        visible: root.moduleVisible("recording")
        x: root.moduleX("recording")
        width: recordingContent.implicitWidth + 16
        height: root.moduleHeight
        radius: root.appearance.radius
        color: recordingHover.hovered ? theme.surfaceHover
            : root.isGrouped("recording") || root.appearance.pillsTransparent
                || root.appearance.transparentBarSlanted || root.appearance.statusIsland
                ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"
        visible: root.moduleVisible("media")
        x: root.moduleX("media")
        width: mediaContent.implicitWidth + 16
        height: root.moduleHeight
        radius: root.appearance.radius
        color: mediaHover.hovered ? theme.surfaceHover
            : root.isGrouped("media") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface


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
                visible: root.appearance.mediaTitleVisible !== false
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

        visible: root.moduleVisible("audio")
        x: root.moduleX("audio")
        width: 76
        height: root.moduleHeight
        radius: root.appearance.radius
        color: audioHover.hovered ? theme.surfaceHover
            : root.isGrouped("audio") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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
                visible: root.appearance.audioMeterVisible !== false
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
        id: bluetoothButton

        visible: root.moduleVisible("bluetooth")
        x: root.moduleX("bluetooth")
        width: root.appearance.workspaceButtonSize
        height: root.moduleHeight
        radius: root.appearance.radius
        color: bluetoothHover.hovered ? theme.surfaceHover
            : root.isGrouped("bluetooth") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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

        visible: root.moduleVisible("tray")
        x: root.moduleX("tray")
        width: root.appearance.workspaceButtonSize
        height: root.moduleHeight
        radius: root.appearance.radius
        color: trayHover.hovered ? theme.surfaceHover
            : root.isGrouped("tray") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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

        visible: root.moduleVisible("network")
        x: root.moduleX("network")
        width: root.appearance.workspaceButtonSize
        height: root.moduleHeight
        radius: root.appearance.radius
        color: networkHover.hovered ? theme.surfaceHover
            : root.isGrouped("network") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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

        visible: root.moduleVisible("battery")
        x: root.moduleX("battery")
        width: batteryContent.implicitWidth + 16
        height: root.moduleHeight
        radius: root.appearance.radius
        color: batteryHover.hovered ? theme.surfaceHover
            : root.isGrouped("battery") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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
                visible: root.appearance.batteryPercentageVisible !== false
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

        visible: root.moduleVisible("clock")
        x: root.moduleX("clock")
        width: clockContent.implicitWidth + 16
        height: root.moduleHeight
        radius: root.appearance.radius
        color: clockHover.hovered ? theme.surfaceHover
            : root.isGrouped("clock") || root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        border.width: root.appearance.barTransparentBorder && !root.appearance.statusIsland ? 1 : 0
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
