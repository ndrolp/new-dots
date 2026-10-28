import Quickshell
import Quickshell.Networking
import QtQuick
import "../../config" as Config
import "." as Panels
import "../StatusText.js" as StatusText

// The network popup: turning Wi-Fi on and off, the networks to join, and the
// password of a new one.
BarPopup {
    id: root

    readonly property var wifi: wifiDevice()
    // The network asking for its password, or null.
    property var passwordNetwork: null
    property string searchQuery: ""

    function wifiDevice() {
        const devices = Networking.devices.values;

        for (let index = 0; index < devices.length; index++) {
            if (DeviceType.toString(devices[index].type) === "Wifi")
                return devices[index];
        }

        return null;
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

    popup: "network"
    implicitWidth: Math.min(420, Math.max(300,
        root.barWindow.width - root.appearance.horizontalPadding * 2))

    onRevealChanged: {
        if (reveal > 0 && wifi)
            wifi.scannerEnabled = true;
    }

    Config.Theme {
        id: theme
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
                subtitle: root.wifi && root.wifi.connected
                    ? "Connected to " + StatusText.connectedNetworkName(root.wifi.networks.values)
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
                text: root.searchQuery
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

                onTextEdited: root.searchQuery = text
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
                        model: root.wifi ? root.wifi.networks : []

                        delegate: PopupRow {
                            id: networkRow

                            required property var modelData

                            readonly property bool matchesSearch: modelData.name.toLowerCase()
                                .includes(root.searchQuery.trim().toLowerCase())

                            appearance: root.appearance
                            width: parent.width
                            height: Networking.wifiEnabled && matchesSearch ? 36 : 0
                            visible: height > 0

                            Behavior on height {
                                NumberAnimation {
                                    duration: root.appearance.motion.short
                                    easing.type: root.appearance.motion.easing
                                }
                            }

                            Panels.Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: StatusText.wifiIcon(networkRow.modelData)
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
