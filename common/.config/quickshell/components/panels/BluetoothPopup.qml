import Quickshell
import Quickshell.Bluetooth
import QtQuick
import "../../config" as Config
import "." as Panels
import "BluetoothDevices.js" as BluetoothDevices

// The Bluetooth popup: turning Bluetooth on and off, and the devices to pair
// with or connect to.
BarPopup {
    id: root

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

    Config.Theme {
        id: theme
    }

    BluetoothPower {
        id: bluetoothPower
    }

    Connections {
        target: root.adapter

        function onEnabledChanged() {
            if (root.visible)
                root.startDiscovery();
        }
    }

    Instantiator {
        model: root.adapter ? root.adapter.devices : []

        delegate: Connections {
            required property var modelData

            target: modelData

            function onPairedChanged() {
                if (!modelData.paired || !root.pairRequests[modelData.address])
                    return;
                modelData.trusted = true;
                const requests = Object.assign({}, root.pairRequests);
                delete requests[modelData.address];
                root.pairRequests = requests;
            }
        }
    }

    Column {
        width: parent.width
        spacing: 4

        PopupHeader {
            appearance: root.appearance
            icon: "󰂯"
            iconColor: root.adapter && root.adapter.enabled
                ? theme.accent : theme.textMuted
            title: "Bluetooth"
            subtitle: !root.adapter ? "No adapter found"
                : bluetoothPower.error !== "" ? bluetoothPower.error
                : !root.adapter.enabled ? "Bluetooth is off"
                : root.adapter.discovering ? "Scanning for devices"
                : "Choose a device"

            PopupSwitch {
                appearance: root.appearance
                checked: !!root.adapter && root.adapter.enabled
                enabled: root.adapter !== null
                onToggled: bluetoothPower.setEnabled(!root.adapter.enabled)
            }
        }

        Item {
            width: 1
            height: 4
        }

        PopupLabel {
            appearance: root.appearance
            visible: root.adapter !== null
                && root.adapter.enabled
                && root.devices.length === 0
            text: "No devices found yet"
            font.pixelSize: root.appearance.textSize - 1
        }

        Flickable {
            width: parent.width
            height: root.adapter && root.adapter.enabled
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
                    model: root.devices

                    delegate: PopupRow {
                        id: deviceRow

                        required property var modelData

                        appearance: root.appearance
                        width: parent.width
                        height: root.adapter && root.adapter.enabled ? 36 : 0
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
                                    root.pair(deviceRow.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
