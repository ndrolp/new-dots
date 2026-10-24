import QtQuick
import QtTest
import "../components/panels/BluetoothDevices.js" as BluetoothDevices

// The Bluetooth popup lists devices by their real name only: a device found
// mid-scan stays hidden until its name arrives, while paired and connected
// devices always show.
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

    function test_aFoundDeviceWithoutANameIsHidden() {
        const nameless = device({});
        const headphones = device({ deviceName: "Headphones", name: "Headphones" });

        compare(labels(BluetoothDevices.visibleDevices([nameless, headphones])), ["Headphones"]);
    }

    function test_aFoundDeviceNamedByItsAddressIsHidden() {
        const addressed = device({ deviceName: "AA-BB-CC-DD-EE-FF" });

        compare(BluetoothDevices.visibleDevices([addressed]).length, 0);
    }

    function test_pairedAndConnectedDevicesShowEvenWithoutAName() {
        const paired = device({ name: "Old speaker", paired: true });
        const connected = device({ name: "Car", connected: true });

        compare(BluetoothDevices.visibleDevices([paired, connected]).length, 2);
    }

    function test_connectedDevicesComeFirstThenPairedThenFound() {
        const found = device({ deviceName: "Neighbour TV" });
        const paired = device({ deviceName: "Speaker", paired: true });
        const connected = device({ deviceName: "Headphones", paired: true, connected: true });

        compare(labels(BluetoothDevices.visibleDevices([found, paired, connected])),
            ["Headphones", "Speaker", "Neighbour TV"]);
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
        compare(BluetoothDevices.label(device({ paired: true })), "Unknown device");
    }
}
