import QtQuick
import QtTest
import "../components/panels/BluetoothDevices.js" as BluetoothDevices

// The Bluetooth popup lists every device it finds. A device without a name
// shows as "Unnamed device" with the end of its address, dimmed unless it is
// paired or connected, and listed last until its name arrives.
TestCase {
    name: "BluetoothDevices"

    function device(fields) {
        return Object.assign({
            deviceName: "",
            name: "AA:BB:CC:DD:EE:FF",
            address: "AA:BB:CC:DD:EE:FF",
            paired: false,
            connected: false
        }, fields);
    }

    function labels(devices) {
        return devices.map(d => BluetoothDevices.label(d));
    }

    // A device the adapter found, whose name can arrive mid-scan.
    Component {
        id: foundDevice

        QtObject {
            property string deviceName: ""
            property string name: "38-EE-C2-A8-DC-59"
            property string address: "38:EE:C2:A8:DC:59"
            property bool paired: false
            property bool connected: false
        }
    }

    function test_aFoundDeviceWithoutANameIsListedAsUnnamed() {
        const nameless = device({});

        compare(labels(BluetoothDevices.visibleDevices([nameless])), ["Unnamed device"]);
    }

    function test_aDeviceNamedByItsAddressIsUnnamed() {
        const addressed = device({ deviceName: "AA-BB-CC-DD-EE-FF", name: "AA-BB-CC-DD-EE-FF" });

        compare(BluetoothDevices.label(addressed), "Unnamed device");
        verify(!BluetoothDevices.isNamed(addressed));
    }

    function test_anUnnamedDeviceIsIdentifiedByTheLastTwoBytesOfItsAddress() {
        compare(BluetoothDevices.identifier(device({ address: "38:ee:c2:a8:dc:59" })), "DC:59");
        compare(BluetoothDevices.identifier(device({ address: "38-EE-C2-A8-DC-59" })), "DC:59");
    }

    function test_aNamedDeviceHasNoIdentifier() {
        compare(BluetoothDevices.identifier(device({ deviceName: "Headphones" })), "");
    }

    function test_onlyUnnamedDevicesThatAreNotYoursAreDimmed() {
        verify(BluetoothDevices.isDimmed(device({})));
        verify(!BluetoothDevices.isDimmed(device({ paired: true })));
        verify(!BluetoothDevices.isDimmed(device({ connected: true })));
        verify(!BluetoothDevices.isDimmed(device({ deviceName: "Neighbour TV" })));
    }

    function test_connectedThenPairedThenFoundThenUnnamed() {
        const unnamed = device({});
        const found = device({ deviceName: "Neighbour TV" });
        const paired = device({ deviceName: "Speaker", paired: true });
        const connected = device({ deviceName: "Headphones", paired: true, connected: true });

        compare(labels(BluetoothDevices.visibleDevices([unnamed, found, paired, connected])),
            ["Headphones", "Speaker", "Neighbour TV", "Unnamed device"]);
    }

    function test_anUnnamedPairedDeviceStaysWithThePairedOnes() {
        const found = device({ deviceName: "Neighbour TV" });
        const paired = device({ paired: true });

        compare(labels(BluetoothDevices.visibleDevices([found, paired])),
            ["Unnamed device", "Neighbour TV"]);
    }

    function test_devicesInTheSameGroupKeepTheirOrder() {
        const first = device({ deviceName: "Keyboard" });
        const second = device({ deviceName: "Mouse" });
        const third = device({ deviceName: "Gamepad" });

        compare(labels(BluetoothDevices.visibleDevices([first, second, third])),
            ["Keyboard", "Mouse", "Gamepad"]);
    }

    function test_aDeviceWithoutANameIsLabelledByItsAliasNeverABareAddress() {
        compare(BluetoothDevices.label(device({ name: "Old speaker", paired: true })), "Old speaker");
        compare(BluetoothDevices.label(device({ paired: true })), "Unnamed device");
    }

    function test_aNameThatArrivesLaterMovesTheDeviceUpAndUndimsIt() {
        const late = createTemporaryObject(foundDevice, this);
        const other = createTemporaryObject(foundDevice, this, { deviceName: "Neighbour TV" });
        const list = createTemporaryQmlObject(
            "import QtQml; QtObject { property var devices: [] }", this);
        list.devices = Qt.binding(() => BluetoothDevices.visibleDevices([late, other]));

        compare(labels(list.devices), ["Neighbour TV", "Unnamed device"]);
        verify(BluetoothDevices.isDimmed(late));

        late.deviceName = "Headphones";
        late.name = "Headphones";

        compare(labels(list.devices), ["Headphones", "Neighbour TV"]);
        verify(!BluetoothDevices.isDimmed(late));
        compare(BluetoothDevices.identifier(late), "");
    }
}
