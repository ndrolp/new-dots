import Quickshell
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
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
        anchor.rect.x: Math.max(root.appearance.horizontalPadding, root.barWindow.width - 380)
        anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
        implicitWidth: 364
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
                                root.popupClosed("audio");
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
                        width: parent.width - 38 - 10 - parent.children[1].implicitWidth - wifiToggle.width
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
