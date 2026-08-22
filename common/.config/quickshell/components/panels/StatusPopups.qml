import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../../config" as Config

Item {
    id: root

    required property var appearance
    required property var barWindow
    property string activePopup: ""
    property var player: null
    property var passwordNetwork: null
    signal popupClosed(string popup)
    signal audioSinkSelected(var sink)

    Config.Theme {
        id: theme
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

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    function wifiDevice() {
        const devices = Networking.devices.values;

        for (let index = 0; index < devices.length; index++) {
            if (DeviceType.toString(devices[index].type) === "Wifi")
                return devices[index];
        }

        return null;
    }

    function formatDuration(seconds) {
        const totalSeconds = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(totalSeconds / 60);
        const remainingSeconds = totalSeconds % 60;
        return minutes + ":" + (remainingSeconds < 10 ? "0" : "") + remainingSeconds;
    }

    function sinkIcon(sink) {
        const description = String(sink.description || "").toLowerCase();

        if (description.includes("headphone") || description.includes("headset"))
            return "󰋋";
        if (description.includes("hdmi") || description.includes("displayport"))
            return "󰍹";
        if (description.includes("bluetooth"))
            return "󰂯";
        return "󰓃";
    }

    function wifiIcon(network) {
        if (network.signalStrength >= 75)
            return "󰤨";
        if (network.signalStrength >= 50)
            return "󰤥";
        if (network.signalStrength >= 25)
            return "󰤢";
        return "󰤟";
    }

    function manageNetwork(network) {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            passwordNetwork = network;
        }
    }

    function connectedNetworkName(wifi) {
        if (!wifi)
            return "";

        const networks = wifi.networks.values;
        for (let index = 0; index < networks.length; index++) {
            if (networks[index].connected)
                return networks[index].name;
        }

        return "";
    }

    function bluetoothDeviceName(device) {
        return device.deviceName || device.name || device.address;
    }

    function batteryIcon(battery) {
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

    function batteryStateLabel(battery) {
        if (!battery)
            return "Battery unavailable";
        if (battery.state === UPowerDeviceState.Charging)
            return "Charging";
        if (battery.state === UPowerDeviceState.FullyCharged)
            return "Fully charged";
        if (battery.state === UPowerDeviceState.PendingCharge)
            return "Waiting to charge";
        if (battery.state === UPowerDeviceState.PendingDischarge)
            return "Waiting to discharge";
        return "Discharging";
    }

    component PopupCard: Rectangle {
        color: theme.backgroundSecondary
        radius: Math.max(10, root.appearance.radius)
        border.color: theme.border
        border.width: 1
    }

    PopupWindow {
        id: mediaPopup

        property real reveal: root.activePopup === "media" ? 1 : 0
        readonly property var player: root.player

        onVisibleChanged: {
            if (!visible && root.activePopup === "media")
                root.popupClosed("media");
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding, root.barWindow.width - 480)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 364
        implicitHeight: 224
        color: "transparent"

        Behavior on reveal {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: mediaCard

            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 16 * (1 - mediaPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: mediaPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {
                    width: 136
                    height: 136
                    radius: 20
                    color: theme.green

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: mediaPopup.player ? mediaPopup.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        id: sinkCard

                        anchors.fill: parent
                        visible: parent.children[0].status !== Image.Ready
                        radius: parent.radius
                        color: theme.green

                        Text {
                            anchors.centerIn: parent
                            text: "󰎈"
                            color: theme.background
                            font.pixelSize: 36
                        }
                    }
                }

                Column {
                    width: parent.width - 152
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        width: parent.width
                        text: mediaPopup.player
                            ? (mediaPopup.player.trackTitle || mediaPopup.player.identity)
                            : "Nothing playing"
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize + 3
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: mediaPopup.player ? mediaPopup.player.trackArtist : ""
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize
                        font.bold: true
                    }

                    Column {
                        width: parent.width
                        visible: !!mediaPopup.player && mediaPopup.player.lengthSupported
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: theme.backgroundSecondary

                            Rectangle {
                                width: parent.width * Math.min(1, Math.max(0,
                                    mediaPopup.player && mediaPopup.player.length > 0
                                    ? mediaPopup.player.position / mediaPopup.player.length : 0))
                                height: parent.height
                                radius: parent.radius
                                color: theme.green
                            }
                        }

                        Row {
                            width: parent.width

                            Text {
                                id: currentTime

                                text: root.formatDuration(mediaPopup.player ? mediaPopup.player.position : 0)
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }

                            Item {
                                width: parent.width - currentTime.implicitWidth - trackLength.implicitWidth
                                height: 1
                            }

                            Text {
                                id: trackLength

                                text: root.formatDuration(mediaPopup.player ? mediaPopup.player.length : 0)
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: previousHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: previousHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                color: theme.text
                                font.pixelSize: 18
                            }

                            TapHandler {
                                enabled: !!mediaPopup.player && mediaPopup.player.canGoPrevious
                                onTapped: mediaPopup.player.previous()
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 21
                            color: playHover.hovered ? theme.accentHover : theme.green

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: playHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: mediaPopup.player && mediaPopup.player.isPlaying ? "󰏤" : "󰐊"
                                color: theme.background
                                font.pixelSize: 22
                            }

                            TapHandler {
                                enabled: !!mediaPopup.player && mediaPopup.player.canTogglePlaying
                                onTapped: mediaPopup.player.togglePlaying()
                            }
                        }

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: nextHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: nextHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: theme.text
                                font.pixelSize: 18
                            }

                            TapHandler {
                                enabled: !!mediaPopup.player && mediaPopup.player.canGoNext
                                onTapped: mediaPopup.player.next()
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: sinkPopup

        property real reveal: root.activePopup === "audio" ? 1 : 0

        onVisibleChanged: {
            if (!visible && root.activePopup === "audio")
                root.popupClosed("audio");
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding,
            root.barWindow.width - implicitWidth - root.appearance.horizontalPadding)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 500
        implicitHeight: sinkList.implicitHeight + 64
        color: "transparent"

        Behavior on reveal {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 12 * (1 - sinkPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: sinkPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Column {
                id: sinkList

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    spacing: 10

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "󰓃"
                            color: theme.background
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Audio output"
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 2
                            font.bold: true
                        }

                        Text {
                            text: "Choose where sound plays"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }
                    }
                }

                Repeater {
                    model: Pipewire.nodes.values

                    delegate: Rectangle {
                        required property var modelData

                        visible: modelData.isSink
                        width: parent.width
                        height: visible ? 52 : 0
                        radius: root.appearance.radius
                        color: Pipewire.defaultAudioSink === modelData || sinkHover.hovered
                            ? theme.surfaceHover : theme.backgroundSecondary

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        HoverHandler {
                            id: sinkHover
                        }

                        Rectangle {
                            id: sinkIconBackground

                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: Pipewire.defaultAudioSink === modelData ? theme.accent : theme.surface

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.sinkIcon(modelData)
                                color: Pipewire.defaultAudioSink === modelData ? theme.background : theme.textMuted
                                font.pixelSize: 17
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 52
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.description
                            color: Pipewire.defaultAudioSink === modelData ? theme.accent : theme.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                Pipewire.preferredDefaultAudioSink = modelData;
                                root.audioSinkSelected(modelData);
                                root.popupClosed("audio");
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: trayPopup

        property real reveal: root.activePopup === "tray" ? 1 : 0
        property var selectedTrayItem: null
        property var menuStack: []
        readonly property int visibleItemCount: SystemTray.items.values.length
            + (selectedTrayItem !== null
                ? trayMenu.children.values.length + (menuStack.length > 0 ? 1 : 0) : 0)

        function returnToParentMenu() {
            const parentStack = menuStack.slice(0, -1);

            menuStack = parentStack;
            trayMenu.menu = parentStack.length > 0
                ? parentStack[parentStack.length - 1] : selectedTrayItem.menu;
        }

        function triggerMenuEntry(entry) {
            entry.triggered();
            trayActionClose.restart();
        }

        onVisibleChanged: {
            if (!visible && root.activePopup === "tray") {
                selectedTrayItem = null;
                menuStack = [];
                root.popupClosed("tray");
            }
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding, root.barWindow.width - implicitWidth - root.appearance.horizontalPadding)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 220
        implicitHeight: Math.max(88, Math.min(328,
            visibleItemCount * 44 + 48))
        color: "transparent"

        QsMenuOpener {
            id: trayMenu
        }

        Timer {
            id: trayActionClose

            interval: 100
            onTriggered: root.popupClosed("tray")
        }

        Behavior on reveal {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 12 * (1 - trayPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: trayPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Column {
                id: trayList

                anchors.fill: parent
                anchors.margins: 12
                spacing: 2

                move: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    visible: SystemTray.items.values.length === 0
                    text: "No tray items"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                Repeater {
                    model: SystemTray.items

                    delegate: Column {
                        required property var modelData

                        readonly property bool expanded: trayPopup.selectedTrayItem === modelData

                        width: trayList.width
                        height: trayItemRow.height + (expanded
                            ? inlineMenu.implicitHeight + spacing : 0)
                        spacing: 0

                        Behavior on height {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: trayItemRow

                            width: parent.width
                            height: 42
                            radius: root.appearance.radius
                            color: trayItemHover.hovered ? theme.surfaceHover
                                : trayPopup.selectedTrayItem === modelData ? theme.backgroundSecondary : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: trayItemHover
                            }

                            Image {
                                id: trayIcon

                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !trayIcon.visible
                                text: "󰍜"
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize
                                font.bold: true
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 42
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.tooltipTitle || modelData.title || modelData.id
                                color: theme.text
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize - 1
                                font.bold: true
                            }

                            TapHandler {
                                onTapped: {
                                    if (modelData.hasMenu) {
                                        if (trayPopup.selectedTrayItem === modelData) {
                                            trayMenu.menu = null;
                                            trayPopup.selectedTrayItem = null;
                                            trayPopup.menuStack = [];
                                        } else {
                                            trayPopup.selectedTrayItem = modelData;
                                            trayPopup.menuStack = [];
                                            trayMenu.menu = modelData.menu;
                                            modelData.opened();
                                        }
                                    } else {
                                        modelData.activate();
                                        root.popupClosed("tray");
                                    }
                                }
                            }
                        }

                        Column {
                            id: inlineMenu

                            width: parent.width
                            height: implicitHeight * (parent.expanded ? 1 : 0)
                            spacing: 0
                            opacity: parent.expanded ? 1 : 0
                            clip: true
                            visible: height > 0

                            Behavior on height {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                visible: trayPopup.menuStack.length > 0
                                width: parent.width
                                height: 32
                                radius: root.appearance.radius
                                color: trayMenuBackHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                                HoverHandler {
                                    id: trayMenuBackHover
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰅁  Back"
                                    color: theme.textMuted
                                    font.pixelSize: root.appearance.textSize - 1
                                    font.bold: true
                                }

                                TapHandler {
                                    onTapped: trayPopup.returnToParentMenu()
                                }
                            }

                            Repeater {
                                model: trayMenu.children

                                delegate: Rectangle {
                                    required property var modelData

                                    width: inlineMenu.width
                                    height: modelData.isSeparator ? 9 : 40
                                    radius: root.appearance.radius
                                    color: !modelData.isSeparator && trayMenuItemHover.hovered
                                        ? theme.surfaceHover : theme.backgroundSecondary

                                    HoverHandler {
                                        id: trayMenuItemHover
                                        enabled: !modelData.isSeparator && modelData.enabled
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 20
                                        height: 1
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: modelData.isSeparator
                                        color: theme.border
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !modelData.isSeparator
                                        text: modelData.text + (modelData.hasChildren ? "  ›" : "")
                                        color: modelData.enabled ? theme.text : theme.textDisabled
                                        elide: Text.ElideRight
                                        font.pixelSize: root.appearance.textSize - 1
                                        font.bold: true
                                    }

                                    TapHandler {
                                        enabled: !modelData.isSeparator && modelData.enabled
                                        onTapped: {
                                            if (modelData.hasChildren) {
                                                modelData.opened();
                                                trayPopup.menuStack = trayPopup.menuStack.concat([modelData]);
                                                trayMenu.menu = modelData;
                                            } else {
                                                trayPopup.triggerMenuEntry(modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: batteryPopup

        readonly property var battery: UPower.displayDevice
        property real reveal: root.activePopup === "battery" ? 1 : 0

        onVisibleChanged: {
            if (!visible && root.activePopup === "battery")
                root.popupClosed("battery");
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding,
            root.barWindow.width - implicitWidth - root.appearance.horizontalPadding)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 300
        implicitHeight: 216
        color: "transparent"

        Behavior on reveal {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 12 * (1 - batteryPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: batteryPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        color: batteryPopup.battery
                            && batteryPopup.battery.state === UPowerDeviceState.Charging
                            ? theme.yellow : theme.backgroundSecondary

                        Text {
                            anchors.centerIn: parent
                            text: root.batteryIcon(batteryPopup.battery)
                            color: batteryPopup.battery
                                && batteryPopup.battery.state === UPowerDeviceState.Charging
                                ? theme.background : theme.yellow
                            font.pixelSize: 25
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.batteryStateLabel(batteryPopup.battery)
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 3
                            font.bold: true
                        }

                        Text {
                            text: batteryPopup.battery
                                ? Math.round(batteryPopup.battery.percentage * 100) + "%"
                                : "No battery detected"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize - 1
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: theme.backgroundSecondary

                    Rectangle {
                        width: parent.width * (batteryPopup.battery
                            ? Math.max(0, Math.min(1, batteryPopup.battery.percentage)) : 0)
                        height: parent.height
                        radius: parent.radius
                        color: batteryPopup.battery
                            && batteryPopup.battery.state === UPowerDeviceState.Charging
                            ? theme.yellow : theme.green
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: theme.border
                }

                Row {
                    width: parent.width

                    Column {
                        width: parent.width / 2
                        spacing: 3

                        Text {
                            text: "BATTERY HEALTH"
                            color: theme.textMuted
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Text {
                            text: batteryPopup.battery && batteryPopup.battery.healthSupported
                                ? Math.round(batteryPopup.battery.healthPercentage * 100) + "%"
                                : "Unavailable"
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 1
                            font.bold: true
                        }
                    }

                    Column {
                        width: parent.width / 2
                        spacing: 3

                        Text {
                            text: "POWER DRAW"
                            color: theme.textMuted
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Text {
                            text: batteryPopup.battery
                                ? Math.abs(batteryPopup.battery.changeRate).toFixed(1) + " W"
                                : "Unavailable"
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 1
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: bluetoothPopup

        readonly property var adapter: Bluetooth.defaultAdapter
        property real reveal: root.activePopup === "bluetooth" ? 1 : 0

        onVisibleChanged: {
            if (!visible && root.activePopup === "bluetooth")
                root.popupClosed("bluetooth");
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding,
            root.barWindow.width - implicitWidth - root.appearance.horizontalPadding)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 400
        implicitHeight: Math.max(132, bluetoothList.implicitHeight + 64)
        color: "transparent"

        onRevealChanged: {
            if (reveal > 0 && adapter && adapter.enabled)
                adapter.discovering = true;
        }

        Behavior on reveal {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 12 * (1 - bluetoothPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: bluetoothPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Column {
                id: bluetoothList

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                            ? theme.blue : theme.backgroundSecondary

                        Text {
                            anchors.centerIn: parent
                            text: "󰂯"
                            color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                                ? theme.background : theme.textMuted
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Bluetooth"
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 2
                            font.bold: true
                        }

                        Text {
                            text: !bluetoothPopup.adapter ? "No adapter found"
                                : !bluetoothPopup.adapter.enabled ? "Bluetooth is off"
                                : bluetoothPopup.adapter.discovering ? "Scanning for devices"
                                : "Choose a device"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - 38 - parent.children[1].implicitWidth
                            - bluetoothToggle.width - (parent.spacing * 3))
                        height: 1
                    }

                    Rectangle {
                        id: bluetoothToggle

                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        height: 28
                        radius: root.appearance.radius
                        color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                            ? theme.blue : theme.backgroundSecondary

                        Rectangle {
                            x: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                                ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 11
                            color: theme.text

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        TapHandler {
                            enabled: bluetoothPopup.adapter !== null
                            onTapped: bluetoothPopup.adapter.enabled = !bluetoothPopup.adapter.enabled
                        }
                    }
                }

                Text {
                    visible: bluetoothPopup.adapter !== null
                        && bluetoothPopup.adapter.enabled
                        && bluetoothPopup.adapter.devices.values.length === 0
                    text: "No devices found yet"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                Repeater {
                    model: bluetoothPopup.adapter ? bluetoothPopup.adapter.devices : []

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? 52 : 0
                        visible: height > 0
                        radius: root.appearance.radius
                        color: modelData.connected || bluetoothDeviceHover.hovered
                            ? theme.surfaceHover : theme.backgroundSecondary

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        HoverHandler {
                            id: bluetoothDeviceHover
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰂯"
                            color: modelData.connected ? theme.blue : theme.textMuted
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 44
                            anchors.rightMargin: 86
                            verticalAlignment: Text.AlignVCenter
                            text: root.bluetoothDeviceName(modelData)
                            color: modelData.connected ? theme.blue : theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.connected ? "Connected"
                                : modelData.pairing ? "Pairing"
                                : modelData.paired ? "Connect" : "Pair"
                            color: modelData.connected ? theme.blue : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else if (modelData.paired)
                                    modelData.connect();
                                else
                                    modelData.pair();
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: networkPopup

        readonly property var wifi: root.wifiDevice()

        property real reveal: root.activePopup === "network" ? 1 : 0

        onVisibleChanged: {
            if (!visible && root.activePopup === "network")
                root.popupClosed("network");
        }
        visible: reveal > 0
        anchor.window: root.barWindow
        anchor.rect.x: Math.max(root.appearance.horizontalPadding, root.barWindow.width - 380)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 364
        implicitHeight: root.passwordNetwork ? 304 : networkList.implicitHeight + 64
        color: "transparent"

        onRevealChanged: {
            if (reveal > 0 && wifi)
                wifi.scannerEnabled = true;
        }

        Behavior on reveal {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: networkCard

            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: 12 - 12 * (1 - networkPopup.reveal)
            radius: root.appearance.radius
            color: theme.surface
            opacity: networkPopup.reveal

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#73000000"
                shadowBlur: 0.65
                shadowVerticalOffset: 6
            }

            Column {
                id: networkList

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 19
                        color: Networking.wifiEnabled ? theme.purple : theme.backgroundSecondary

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰤨"
                            color: Networking.wifiEnabled ? theme.background : theme.textMuted
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "Wi-Fi"
                            color: theme.text
                            font.pixelSize: root.appearance.textSize + 2
                            font.bold: true
                        }

                        Text {
                            text: networkPopup.wifi && networkPopup.wifi.connected
                                ? "Connected to " + root.connectedNetworkName(networkPopup.wifi)
                                : Networking.wifiEnabled ? "Choose a network" : "Wi-Fi is off"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - 38 - parent.children[1].implicitWidth
                            - wifiToggle.width - (parent.spacing * 3))
                        height: 1
                    }

                    Rectangle {
                        id: wifiToggle

                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        height: 28
                        radius: root.appearance.radius
                        color: Networking.wifiEnabled ? theme.purple : theme.backgroundSecondary

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        Rectangle {
                            x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 11
                            color: theme.text

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        TapHandler {
                            onTapped: Networking.wifiEnabled = !Networking.wifiEnabled
                        }
                    }
                }

                Repeater {
                    model: networkPopup.wifi ? networkPopup.wifi.networks : []

                    delegate: Rectangle {
                        required property var modelData

                        width: parent.width
                        height: Networking.wifiEnabled ? 52 : 0
                        visible: Networking.wifiEnabled
                        radius: root.appearance.radius
                        color: modelData.connected || networkHover.hovered
                            ? theme.surfaceHover : theme.backgroundSecondary

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        HoverHandler {
                            id: networkHover
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.wifiIcon(modelData)
                            color: modelData.connected ? theme.purple : theme.textMuted
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 44
                            anchors.rightMargin: 56
                            verticalAlignment: Text.AlignVCenter
                            text: modelData.name
                            color: modelData.connected ? theme.purple : theme.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.connected ? "󰄬"
                                : modelData.security === WifiSecurityType.Open ? "" : "󰌾"
                            color: modelData.connected ? theme.purple : theme.textMuted
                            font.pixelSize: 16
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: root.manageNetwork(modelData)
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: theme.surface
                visible: root.passwordNetwork !== null

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: theme.purple

                        Text {
                            anchors.centerIn: parent
                            text: "󰌾"
                            color: theme.background
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Text {
                        text: root.passwordNetwork ? root.passwordNetwork.name : ""
                        color: theme.text
                        font.pixelSize: root.appearance.textSize + 3
                        font.bold: true
                    }

                    Text {
                        text: "Enter the Wi-Fi password to connect."
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: true
                    }

                    TextField {
                        id: passwordInput

                        width: parent.width
                        height: 40
                        echoMode: TextInput.Password
                        placeholderText: "Password"
                        color: theme.text
                        font.pixelSize: root.appearance.textSize
                        font.bold: true
                        selectByMouse: true
                        background: Rectangle {
                            radius: root.appearance.radius
                            color: theme.backgroundSecondary
                            border.color: passwordInput.activeFocus ? theme.purple : "transparent"
                            border.width: 1
                        }
                        onAccepted: {
                            if (text !== "" && root.passwordNetwork) {
                                root.passwordNetwork.connectWithPsk(text);
                                root.passwordNetwork = null;
                                text = "";
                            }
                        }
                    }

                    Row {
                        spacing: 8

                        Rectangle {
                            width: 78
                            height: 34
                            radius: root.appearance.radius
                            color: cancelHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: cancelHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: theme.text
                                font.pixelSize: root.appearance.textSize - 1
                                font.bold: true
                            }

                            TapHandler {
                                onTapped: {
                                    root.passwordNetwork = null;
                                    passwordInput.text = "";
                                }
                            }
                        }

                        Rectangle {
                            width: 86
                            height: 34
                            radius: root.appearance.radius
                            color: connectHover.hovered ? theme.accentHover : theme.purple

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            HoverHandler {
                                id: connectHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Connect"
                                color: theme.background
                                font.pixelSize: root.appearance.textSize - 1
                                font.bold: true
                            }

                            TapHandler {
                                onTapped: {
                                    if (passwordInput.text !== "" && root.passwordNetwork) {
                                        root.passwordNetwork.connectWithPsk(passwordInput.text);
                                        root.passwordNetwork = null;
                                        passwordInput.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
