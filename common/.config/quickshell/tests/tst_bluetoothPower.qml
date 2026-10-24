import QtQuick
import QtTest
import "../components/panels/BluetoothPower.js" as BluetoothPower

// Turning Bluetooth on from the Bluetooth popup or the Control center: a
// blocked adapter is unblocked with rfkill first, and a failed attempt says
// why.
TestCase {
    name: "BluetoothPower"

    function test_turningOnAnUnblockedAdapterEnablesIt() {
        compare(BluetoothPower.step(true, false), "enable");
    }

    function test_turningOnABlockedAdapterUnblocksItFirst() {
        compare(BluetoothPower.step(true, true), "unblock");
    }

    function test_turningOffDisablesTheAdapterEvenWhenBlocked() {
        compare(BluetoothPower.step(false, false), "disable");
        compare(BluetoothPower.step(false, true), "disable");
    }

    function test_aFailedUnblockBlamesRfkill() {
        compare(BluetoothPower.failure({ unblockFailed: true, blocked: true }),
            "Couldn't unblock Bluetooth (rfkill)");
    }

    function test_anAdapterStillBlockedAfterTheAttemptSaysSo() {
        compare(BluetoothPower.failure({ unblockFailed: false, blocked: true }),
            "Bluetooth is blocked (rfkill)");
    }

    function test_anAdapterThatStaysOffForAnotherReasonSaysItCouldntTurnOn() {
        compare(BluetoothPower.failure({ unblockFailed: false, blocked: false }),
            "Couldn't turn Bluetooth on");
    }
}
