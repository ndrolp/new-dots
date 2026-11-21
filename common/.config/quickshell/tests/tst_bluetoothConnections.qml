import QtQuick
import QtTest
import "../services/BluetoothConnections.js" as BluetoothConnections

// Which Bluetooth devices connected or disconnected since the last read: the
// change events the OSD and the capsule show. A device is only told once it
// has been seen, so the ones connected when the shell starts, or when BlueZ
// first lists them, aren't.
TestCase {
    name: "BluetoothConnections"

    function device(address, connected) {
        return { address: address, deviceName: "Device " + address, connected: connected };
    }

    function changed(known, devices) {
        return BluetoothConnections.read(known, devices).changed.map(d => d.address + (d.connected ? " on" : " off"));
    }

    function test_devicesConnectedAtStartAreNotChanges() {
        compare(changed({}, [device("A", true), device("B", false)]), []);
    }

    function test_aDeviceListedLaterAlreadyConnectedIsNotAChange() {
        const known = BluetoothConnections.read({}, [device("A", false)]).known;
        compare(changed(known, [device("A", false), device("B", true)]), []);
    }

    function test_connectingASeenDeviceIsAChange() {
        const known = BluetoothConnections.read({}, [device("A", false)]).known;
        compare(changed(known, [device("A", true)]), ["A on"]);
    }

    function test_disconnectingASeenDeviceIsAChange() {
        const known = BluetoothConnections.read({}, [device("A", true)]).known;
        compare(changed(known, [device("A", false)]), ["A off"]);
    }

    function test_aDeviceThatStaysAsItWasIsNotAChange() {
        let known = BluetoothConnections.read({}, [device("A", false)]).known;
        known = BluetoothConnections.read(known, [device("A", true)]).known;
        compare(changed(known, [device("A", true)]), []);
    }

    function test_aDeviceThatGoesAwayIsForgotten() {
        let known = BluetoothConnections.read({}, [device("A", false)]).known;
        known = BluetoothConnections.read(known, []).known;
        compare(changed(known, [device("A", true)]), []);
    }

    function test_theChangedDeviceIsTheDeviceItself() {
        const a = device("A", false);
        const known = BluetoothConnections.read({}, [a]).known;
        a.connected = true;
        verify(BluetoothConnections.read(known, [a]).changed[0] === a);
    }
}
