import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "." as Panels
import "BluetoothDevices.js" as BluetoothDevices

Item {
    id: root

    required property var appearance
    required property var barWindow
    required property var pomodoro
    required property var systemMonitor
    property string activePopup: ""
    property var player: null
    property real mediaPosition: 0
    property string mediaTrackKey: ""
    property var passwordNetwork: null
    property var popupAnchorProvider: null
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
        const nextPlayer = activePlayer();
        const trackKey = nextPlayer
            ? nextPlayer.identity + "\u0000" + nextPlayer.trackTitle + "\u0000" + nextPlayer.length : "";

        if (nextPlayer !== player || trackKey !== mediaTrackKey) {
            player = nextPlayer;
            mediaTrackKey = trackKey;
            mediaPosition = player ? player.position : 0;
        } else if (player) {
            mediaPosition = player.isPlaying
                ? Math.min(player.length, mediaPosition + 1) : player.position;
        }
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

    // A popup of this bar, open while it is the active one.
    component BarPopup: PopupFrame {
        appearance: root.appearance
        barWindow: root.barWindow
        anchorProvider: root.popupAnchorProvider
        open: root.activePopup === popup
        onDismissed: root.popupClosed(popup)
    }

    BarPopup {
        id: systemPopup

        popup: "system"
        edge: "left"
        implicitWidth: 360

        Column {
            width: parent.width
            spacing: 6

            PopupHeader {
                appearance: root.appearance
                title: "System resources"

                PopupLabel {
                    appearance: root.appearance
                    text: "Load " + root.systemMonitor.loadAverage
                }
            }

            Repeater {
                model: [
                    { label: "󰍛  CPU", value: Math.round(root.systemMonitor.cpuUsage) + "%" },
                    {
                        label: "󰘚  Memory",
                        value: root.systemMonitor.memoryUsedGiB.toFixed(1)
                            + " / " + root.systemMonitor.memoryTotalGiB.toFixed(1) + " GiB"
                            + " · " + Math.round(root.systemMonitor.memoryUsage) + "%"
                    },
                    {
                        label: "  Temperature",
                        value: root.systemMonitor.temperature > 0
                            ? Math.round(root.systemMonitor.temperature) + "°C" : "--"
                    },
                    {
                        label: "󰋊  Disk",
                        value: root.systemMonitor.diskTotalGiB > 0
                            ? root.systemMonitor.diskUsedGiB.toFixed(0) + " / "
                                + root.systemMonitor.diskTotalGiB.toFixed(0) + " GiB"
                            : "--"
                    },
                    {
                        label: "󰕒  Network",
                        value: "↓ " + root.systemMonitor.formatRate(root.systemMonitor.networkDownloadRate)
                            + "  ↑ " + root.systemMonitor.formatRate(root.systemMonitor.networkUploadRate)
                    },
                    {
                        label: "󰢮  GPU",
                        value: root.systemMonitor.gpuUsage >= 0
                            ? Math.round(root.systemMonitor.gpuUsage) + "% · "
                                + Math.round(root.systemMonitor.gpuTemperature) + "°C"
                            : "Unavailable"
                    }
                ]

                delegate: Item {
                    required property var modelData

                    width: parent.width
                    height: 22

                    Panels.Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 1
                    }

                    Panels.Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.value
                        color: theme.text
                        font.pixelSize: root.appearance.textSize - 1
                    }
                }
            }
        }
    }

    BarPopup {
        id: pomodoroPopup

        popup: "pomodoro"
        implicitWidth: 320

        Column {
            width: parent.width
            spacing: 8

            PopupHeader {
                appearance: root.appearance
                title: "Pomodoro"
            }

            Panels.Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.pomodoro.remainingLabel
                color: root.pomodoro.running ? theme.accent : theme.text
                font.pixelSize: 34
            }

            PopupLabel {
                appearance: root.appearance
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.pomodoro.running ? "Focus session in progress"
                    : root.pomodoro.started ? "Timer paused" : "Choose a focus duration"
            }

            Row {
                width: parent.width
                spacing: 4

                Repeater {
                    model: [25, 30, 45, 60]

                    delegate: PopupButton {
                        required property int modelData

                        appearance: root.appearance
                        width: (parent.width - parent.spacing * 3) / 4
                        label: modelData === 60 ? "1h" : modelData + "m"
                        labelColor: root.pomodoro.durationSeconds === modelData * 60
                            ? theme.accent : theme.textMuted
                        onActivated: root.pomodoro.selectMinutes(modelData)
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 4

                PopupButton {
                    appearance: root.appearance
                    width: 48
                    label: "−10m"
                    onActivated: root.pomodoro.adjustMinutes(-10)
                }

                PopupButton {
                    appearance: root.appearance
                    width: 36
                    label: "−1"
                    onActivated: root.pomodoro.adjustMinutes(-1)
                }

                PopupButton {
                    appearance: root.appearance
                    width: parent.width - 168 - parent.spacing * 4
                    label: root.pomodoro.running ? "Stop" : root.pomodoro.started ? "Resume" : "Start"
                    labelColor: theme.accent
                    labelSize: root.appearance.textSize
                    onActivated: {
                        if (root.pomodoro.running)
                            root.pomodoro.stop();
                        else
                            root.pomodoro.start();
                    }
                }

                PopupButton {
                    appearance: root.appearance
                    width: 36
                    label: "+1"
                    onActivated: root.pomodoro.adjustMinutes(1)
                }

                PopupButton {
                    appearance: root.appearance
                    width: 48
                    label: "+10m"
                    onActivated: root.pomodoro.adjustMinutes(10)
                }
            }

            PopupButton {
                appearance: root.appearance
                visible: root.pomodoro.started
                width: parent.width
                label: "Cancel timer"
                labelColor: theme.red
                onActivated: root.pomodoro.cancel()
            }
        }
    }

    BarPopup {
        id: mediaPopup

        readonly property var player: root.player

        popup: "media"
        implicitWidth: 440

        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                id: mediaArt

                width: 112
                height: 112
                radius: root.appearance.radius
                color: theme.backgroundSecondary
                clip: true

                Image {
                    id: mediaArtImage

                    anchors.fill: parent
                    source: mediaPopup.player ? mediaPopup.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                }

                Panels.Text {
                    anchors.centerIn: parent
                    visible: mediaArtImage.status !== Image.Ready
                    text: "󰎈"
                    color: theme.textMuted
                    font.pixelSize: 32
                }
            }

            Column {
                width: parent.width - mediaArt.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                PopupTitle {
                    appearance: root.appearance
                    width: parent.width
                    text: mediaPopup.player
                        ? (mediaPopup.player.trackTitle || mediaPopup.player.identity)
                        : "Nothing playing"
                }

                Panels.Text {
                    width: parent.width
                    visible: text !== ""
                    text: mediaPopup.player ? mediaPopup.player.trackArtist : ""
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 1
                }

                PopupLabel {
                    appearance: root.appearance
                    width: parent.width
                    visible: !!mediaPopup.player && mediaPopup.player.identity !== ""
                    text: mediaPopup.player ? mediaPopup.player.identity : ""
                }

                Item {
                    width: 1
                    height: 4
                }

                Column {
                    width: parent.width
                    visible: !!mediaPopup.player && mediaPopup.player.lengthSupported
                    spacing: 4

                    PopupProgress {
                        appearance: root.appearance
                        width: parent.width
                        fraction: mediaPopup.player && mediaPopup.player.length > 0
                            ? root.mediaPosition / mediaPopup.player.length : 0
                    }

                    Item {
                        width: parent.width
                        height: currentTime.implicitHeight

                        PopupLabel {
                            id: currentTime

                            appearance: root.appearance
                            anchors.left: parent.left
                            text: root.formatDuration(root.mediaPosition)
                        }

                        PopupLabel {
                            appearance: root.appearance
                            anchors.right: parent.right
                            text: root.formatDuration(mediaPopup.player ? mediaPopup.player.length : 0)
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    PopupButton {
                        appearance: root.appearance
                        width: 32
                        height: 32
                        label: "󰒮"
                        labelSize: 16
                        interactive: !!mediaPopup.player && mediaPopup.player.canGoPrevious
                        onActivated: mediaPopup.player.previous()
                    }

                    PopupButton {
                        appearance: root.appearance
                        width: 36
                        height: 32
                        label: mediaPopup.player && mediaPopup.player.isPlaying ? "󰏤" : "󰐊"
                        labelColor: theme.accent
                        labelSize: 20
                        interactive: !!mediaPopup.player && mediaPopup.player.canTogglePlaying
                        onActivated: mediaPopup.player.togglePlaying()
                    }

                    PopupButton {
                        appearance: root.appearance
                        width: 32
                        height: 32
                        label: "󰒭"
                        labelSize: 16
                        interactive: !!mediaPopup.player && mediaPopup.player.canGoNext
                        onActivated: mediaPopup.player.next()
                    }
                }
            }
        }
    }

    BarPopup {
        id: sinkPopup

        popup: "audio"
        implicitWidth: 440

        Column {
            width: parent.width
            spacing: 4

            PopupHeader {
                appearance: root.appearance
                icon: "󰓃"
                iconColor: theme.accent
                title: "Audio output"
                subtitle: "Choose where sound plays"
            }

            Item {
                width: 1
                height: 4
            }

            Repeater {
                model: Pipewire.nodes.values

                delegate: PopupRow {
                    required property var modelData

                    readonly property bool selected: Pipewire.defaultAudioSink === modelData

                    appearance: root.appearance
                    visible: modelData.isSink
                    width: parent.width
                    height: 36

                    Panels.Text {
                        id: sinkIconLabel

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: root.sinkIcon(modelData)
                        color: parent.selected ? theme.accent : theme.textMuted
                        font.pixelSize: 16
                    }

                    Panels.Text {
                        anchors.left: sinkIconLabel.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.description
                        color: parent.selected ? theme.accent : theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 1
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

    BarPopup {
        id: trayPopup

        property var selectedTrayItem: null
        property var menuStack: []

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

        onDismissed: {
            selectedTrayItem = null;
            menuStack = [];
        }
        popup: "tray"
        implicitWidth: 220

        QsMenuOpener {
            id: trayMenu
        }

        Timer {
            id: trayActionClose

            interval: 100
            onTriggered: root.popupClosed("tray")
        }

        Column {
            id: trayList

            width: parent.width
            spacing: 2

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            PopupLabel {
                appearance: root.appearance
                visible: SystemTray.items.values.length === 0
                text: "No tray items"
                font.pixelSize: root.appearance.textSize - 1
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

                    PopupRow {
                        id: trayItemRow

                        appearance: root.appearance
                        width: parent.width
                        height: 34

                        Image {
                            id: trayIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            source: modelData.icon
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        Panels.Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !trayIcon.visible
                            text: "󰍜"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize
                        }

                        Panels.Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.tooltipTitle || modelData.title || modelData.id
                            color: trayItemRow.parent.expanded ? theme.accent : theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 1
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

                        PopupRow {
                            appearance: root.appearance
                            visible: trayPopup.menuStack.length > 0
                            width: parent.width
                            height: 30

                            Panels.Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰅁  Back"
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 1
                            }

                            TapHandler {
                                onTapped: trayPopup.returnToParentMenu()
                            }
                        }

                        Repeater {
                            model: trayMenu.children

                            delegate: PopupRow {
                                required property var modelData

                                appearance: root.appearance
                                width: inlineMenu.width
                                height: modelData.isSeparator ? 9 : 30
                                interactive: !modelData.isSeparator && modelData.enabled

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 36
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    height: 1
                                    visible: modelData.isSeparator
                                    color: theme.border
                                }

                                Panels.Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 36
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !modelData.isSeparator
                                    text: modelData.text + (modelData.hasChildren ? "  ›" : "")
                                    color: modelData.enabled ? theme.text : theme.textDisabled
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize - 1
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

    BarPopup {
        id: batteryPopup

        readonly property var battery: UPower.displayDevice
        readonly property bool charging: !!battery && battery.state === UPowerDeviceState.Charging

        popup: "battery"
        implicitWidth: 340

        Column {
            width: parent.width
            spacing: 10

            PopupHeader {
                appearance: root.appearance
                icon: root.batteryIcon(batteryPopup.battery)
                iconColor: batteryPopup.charging ? theme.yellow : theme.textMuted
                title: root.batteryStateLabel(batteryPopup.battery)
                subtitle: batteryPopup.battery
                    ? Math.round(batteryPopup.battery.percentage * 100) + "%"
                    : "No battery detected"
            }

            PopupProgress {
                appearance: root.appearance
                width: parent.width
                fraction: batteryPopup.battery ? batteryPopup.battery.percentage : 0
                fillColor: batteryPopup.charging ? theme.yellow : theme.green
            }

            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        {
                            label: "Health",
                            value: root.systemMonitor.batteryHealth !== ""
                                ? root.systemMonitor.batteryHealth
                                : batteryPopup.battery && batteryPopup.battery.healthSupported
                                    ? Math.round(batteryPopup.battery.healthPercentage * 100) + "%"
                                    : "Unavailable"
                        },
                        {
                            label: "Power draw",
                            value: batteryPopup.battery
                                ? Math.abs(batteryPopup.battery.changeRate).toFixed(1) + " W"
                                : "Unavailable"
                        },
                        {
                            label: batteryPopup.charging ? "Time to full" : "Time left",
                            value: batteryPopup.charging
                                ? (root.systemMonitor.batteryTimeToFull || "Calculating")
                                : (root.systemMonitor.batteryTimeToEmpty || "Calculating")
                        }
                    ]

                    delegate: Column {
                        required property var modelData

                        width: (parent.width - parent.spacing * 2) / 3
                        spacing: 2

                        PopupLabel {
                            appearance: root.appearance
                            width: parent.width
                            text: modelData.label
                        }

                        Panels.Text {
                            width: parent.width
                            text: modelData.value
                            color: theme.text
                            elide: Text.ElideRight
                            font.pixelSize: root.appearance.textSize - 1
                        }
                    }
                }
            }
        }
    }

    BarPopup {
        id: bluetoothPopup

        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property var devices: adapter
            ? BluetoothDevices.visibleDevices(adapter.devices.values) : []
        // Addresses of devices paired from this popup, trusted once paired.
        property var pairRequests: ({})

        popup: "bluetooth"
        implicitWidth: 380

        // Scan for devices while the popup is open and Bluetooth is on.
        onVisibleChanged: {
            if (visible)
                startDiscovery();
            else if (adapter && adapter.discovering)
                adapter.discovering = false;
        }

        function startDiscovery() {
            if (adapter && adapter.enabled && !adapter.discovering)
                adapter.discovering = true;
        }

        function pair(device) {
            const requests = Object.assign({}, pairRequests);
            requests[device.address] = true;
            pairRequests = requests;
            device.pair();
        }

        BluetoothPower {
            id: bluetoothPower
        }

        Connections {
            target: bluetoothPopup.adapter

            function onEnabledChanged() {
                if (bluetoothPopup.visible)
                    bluetoothPopup.startDiscovery();
            }
        }

        Instantiator {
            model: bluetoothPopup.adapter ? bluetoothPopup.adapter.devices : []

            delegate: Connections {
                required property var modelData

                target: modelData

                function onPairedChanged() {
                    if (!modelData.paired || !bluetoothPopup.pairRequests[modelData.address])
                        return;
                    modelData.trusted = true;
                    const requests = Object.assign({}, bluetoothPopup.pairRequests);
                    delete requests[modelData.address];
                    bluetoothPopup.pairRequests = requests;
                }
            }
        }

        Column {
            width: parent.width
            spacing: 4

            PopupHeader {
                appearance: root.appearance
                icon: "󰂯"
                iconColor: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                    ? theme.accent : theme.textMuted
                title: "Bluetooth"
                subtitle: !bluetoothPopup.adapter ? "No adapter found"
                    : bluetoothPower.error !== "" ? bluetoothPower.error
                    : !bluetoothPopup.adapter.enabled ? "Bluetooth is off"
                    : bluetoothPopup.adapter.discovering ? "Scanning for devices"
                    : "Choose a device"

                PopupSwitch {
                    appearance: root.appearance
                    checked: !!bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                    enabled: bluetoothPopup.adapter !== null
                    onToggled: bluetoothPower.setEnabled(!bluetoothPopup.adapter.enabled)
                }
            }

            Item {
                width: 1
                height: 4
            }

            PopupLabel {
                appearance: root.appearance
                visible: bluetoothPopup.adapter !== null
                    && bluetoothPopup.adapter.enabled
                    && bluetoothPopup.devices.length === 0
                text: "No devices found yet"
                font.pixelSize: root.appearance.textSize - 1
            }

            Flickable {
                width: parent.width
                height: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                    ? Math.min(292, bluetoothRows.implicitHeight) : 0
                contentWidth: width
                contentHeight: bluetoothRows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: height > 0

                Column {
                    id: bluetoothRows

                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: bluetoothPopup.devices

                        delegate: PopupRow {
                            id: deviceRow

                            required property var modelData

                            appearance: root.appearance
                            width: parent.width
                            height: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? 36 : 0
                            visible: height > 0
                            opacity: BluetoothDevices.isDimmed(deviceRow.modelData) ? 0.5 : 1

                            Panels.Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰂯"
                                color: deviceRow.modelData.connected ? theme.accent : theme.textMuted
                                font.pixelSize: 16
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.right: parent.right
                                anchors.rightMargin: 80
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Panels.Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, parent.width
                                        - (deviceIdentifier.visible ? deviceIdentifier.implicitWidth + parent.spacing : 0))
                                    text: BluetoothDevices.label(deviceRow.modelData)
                                    color: deviceRow.modelData.connected ? theme.accent : theme.text
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize - 1
                                }

                                // Tells unnamed devices apart.
                                Panels.Text {
                                    id: deviceIdentifier

                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: text !== ""
                                    text: BluetoothDevices.identifier(deviceRow.modelData)
                                    color: theme.textMuted
                                    font.pixelSize: root.appearance.textSize - 2
                                }
                            }

                            Panels.Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: deviceRow.modelData.connected ? "Connected"
                                    : deviceRow.modelData.pairing ? "Pairing"
                                    : deviceRow.modelData.paired ? "Connect" : "Pair"
                                color: deviceRow.modelData.connected ? theme.accent : theme.textMuted
                                font.pixelSize: root.appearance.textSize - 2
                            }

                            TapHandler {
                                onTapped: {
                                    if (deviceRow.modelData.connected)
                                        deviceRow.modelData.disconnect();
                                    else if (deviceRow.modelData.paired)
                                        deviceRow.modelData.connect();
                                    else
                                        bluetoothPopup.pair(deviceRow.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    BarPopup {
        id: networkPopup

        readonly property var wifi: root.wifiDevice()
        property string searchQuery: ""

        popup: "network"
        implicitWidth: Math.min(420, Math.max(300,
            root.barWindow.width - root.appearance.horizontalPadding * 2))

        onRevealChanged: {
            if (reveal > 0 && wifi)
                wifi.scannerEnabled = true;
        }

        Column {
            width: parent.width

            Column {
                width: parent.width
                visible: root.passwordNetwork === null
                spacing: 4

                PopupHeader {
                    appearance: root.appearance
                    icon: "󰤨"
                    iconColor: Networking.wifiEnabled ? theme.accent : theme.textMuted
                    title: "Wi-Fi"
                    subtitle: networkPopup.wifi && networkPopup.wifi.connected
                        ? "Connected to " + root.connectedNetworkName(networkPopup.wifi)
                        : Networking.wifiEnabled ? "Choose a network" : "Wi-Fi is off"

                    PopupSwitch {
                        appearance: root.appearance
                        checked: Networking.wifiEnabled
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                Item {
                    width: 1
                    height: 4
                }

                PopupTextField {
                    id: networkSearch

                    appearance: root.appearance
                    width: parent.width
                    height: 32
                    visible: Networking.wifiEnabled
                    placeholderText: "Search networks"
                    text: networkPopup.searchQuery
                    leftPadding: 30
                    rightPadding: 28

                    Panels.Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: theme.textMuted
                        font.pixelSize: 14
                    }

                    Panels.Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkSearch.text !== ""
                        text: "󰅖"
                        color: theme.textMuted
                        font.pixelSize: 14

                        TapHandler {
                            onTapped: networkSearch.clear()
                        }
                    }

                    onTextEdited: networkPopup.searchQuery = text
                }

                Flickable {
                    width: parent.width
                    height: Networking.wifiEnabled
                        ? Math.min(260, networkRows.implicitHeight) : 0
                    contentWidth: width
                    contentHeight: networkRows.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: height > 0

                    Column {
                        id: networkRows

                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: networkPopup.wifi ? networkPopup.wifi.networks : []

                            delegate: PopupRow {
                                id: networkRow

                                required property var modelData

                                readonly property bool matchesSearch: modelData.name.toLowerCase()
                                    .includes(networkPopup.searchQuery.trim().toLowerCase())

                                appearance: root.appearance
                                width: parent.width
                                height: Networking.wifiEnabled && matchesSearch ? 36 : 0
                                visible: height > 0

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Panels.Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.wifiIcon(networkRow.modelData)
                                    color: networkRow.modelData.connected ? theme.accent : theme.textMuted
                                    font.pixelSize: 16
                                }

                                Panels.Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 36
                                    anchors.rightMargin: 40
                                    verticalAlignment: Text.AlignVCenter
                                    text: networkRow.modelData.name
                                    color: networkRow.modelData.connected ? theme.accent : theme.text
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize - 1
                                }

                                Panels.Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: networkRow.modelData.connected ? "󰄬"
                                        : networkRow.modelData.security === WifiSecurityType.Open ? "" : "󰌾"
                                    color: networkRow.modelData.connected ? theme.accent : theme.textMuted
                                    font.pixelSize: 14
                                }

                                TapHandler {
                                    onTapped: root.manageNetwork(networkRow.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                visible: root.passwordNetwork !== null
                spacing: 8

                PopupHeader {
                    appearance: root.appearance
                    icon: "󰌾"
                    iconColor: theme.accent
                    title: root.passwordNetwork ? root.passwordNetwork.name : ""
                    subtitle: "Enter the Wi-Fi password to connect."
                }

                PopupTextField {
                    id: passwordInput

                    appearance: root.appearance
                    width: parent.width
                    height: 32
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    onAccepted: {
                        if (text !== "" && root.passwordNetwork) {
                            root.passwordNetwork.connectWithPsk(text);
                            root.passwordNetwork = null;
                            text = "";
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 4

                    PopupButton {
                        appearance: root.appearance
                        width: 72
                        label: "Cancel"
                        onActivated: {
                            root.passwordNetwork = null;
                            passwordInput.text = "";
                        }
                    }

                    PopupButton {
                        appearance: root.appearance
                        width: 80
                        label: "Connect"
                        labelColor: theme.accent
                        onActivated: {
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
