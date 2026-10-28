import QtQuick
import QtTest
import "../components/StatusText.js" as StatusText

// What the popups and the bar elements show for the media position, audio
// outputs, Wi-Fi, the battery and the network connection.
TestCase {
    name: "StatusText"

    function test_durationIsMinutesAndPaddedSeconds() {
        compare(StatusText.duration(0), "0:00");
        compare(StatusText.duration(65), "1:05");
        compare(StatusText.duration(754), "12:34");
    }

    function test_durationDropsFractionsAndNeverGoesNegative() {
        compare(StatusText.duration(59.9), "0:59");
        compare(StatusText.duration(-3), "0:00");
    }

    function test_anHourOrMoreAddsHours() {
        compare(StatusText.duration(3600), "1:00:00");
        compare(StatusText.duration(3723), "1:02:03");
    }

    function test_audioOutputIconFollowsItsDescription() {
        compare(StatusText.audioOutputIcon({ description: "USB Headset Analog Stereo" }), "󰋋");
        compare(StatusText.audioOutputIcon({ description: "Headphones" }), "󰋋");
        compare(StatusText.audioOutputIcon({ description: "HDMI / DisplayPort 1 Output" }), "󰍹");
        compare(StatusText.audioOutputIcon({ description: "Bluetooth speaker" }), "󰂯");
        compare(StatusText.audioOutputIcon({ description: "Built-in Audio Analog Stereo" }), "󰓃");
        compare(StatusText.audioOutputIcon({}), "󰓃");
    }

    function test_wifiIconHasFourSignalSteps() {
        compare(StatusText.wifiIcon({ signalStrength: 90 }), "󰤨");
        compare(StatusText.wifiIcon({ signalStrength: 75 }), "󰤨");
        compare(StatusText.wifiIcon({ signalStrength: 74 }), "󰤥");
        compare(StatusText.wifiIcon({ signalStrength: 50 }), "󰤥");
        compare(StatusText.wifiIcon({ signalStrength: 30 }), "󰤢");
        compare(StatusText.wifiIcon({ signalStrength: 10 }), "󰤟");
    }

    function test_connectedNetworkNameIsTheConnectedOne() {
        const networks = [
            { name: "Neighbours", connected: false },
            { name: "Home", connected: true }
        ];
        compare(StatusText.connectedNetworkName(networks), "Home");
    }

    function test_noConnectedNetworkHasNoName() {
        compare(StatusText.connectedNetworkName([{ name: "Cafe", connected: false }]), "");
        compare(StatusText.connectedNetworkName([]), "");
    }

    // Stands in for UPower's UPowerDeviceState, in its order.
    readonly property var states: ({
        Unknown: 0, Charging: 1, Discharging: 2, Empty: 3,
        FullyCharged: 4, PendingCharge: 5, PendingDischarge: 6
    })

    function battery(state, percentage) {
        return { state: states[state], percentage: percentage };
    }

    function test_batteryIconFallsWithTheCharge() {
        compare(StatusText.batteryIcon(battery("Discharging", 0.9), states), "󰁹");
        compare(StatusText.batteryIcon(battery("Discharging", 0.7), states), "󰁾");
        compare(StatusText.batteryIcon(battery("Discharging", 0.4), states), "󰁻");
        compare(StatusText.batteryIcon(battery("Discharging", 0.15), states), "󰂃");
    }

    function test_batteryIconShowsChargingWhateverTheCharge() {
        compare(StatusText.batteryIcon(battery("Charging", 0.1), states), "󰂄");
        compare(StatusText.batteryIcon(battery("PendingCharge", 0.9), states), "󰂄");
    }

    function test_noBatteryHasItsOwnIconAndLabel() {
        compare(StatusText.batteryIcon(null, states), "󰂑");
        compare(StatusText.batteryStateLabel(null, states), "Battery unavailable");
    }

    function test_batteryStateLabelNamesTheState() {
        compare(StatusText.batteryStateLabel(battery("Charging", 0.5), states), "Charging");
        compare(StatusText.batteryStateLabel(battery("FullyCharged", 1), states), "Fully charged");
        compare(StatusText.batteryStateLabel(battery("PendingCharge", 0.8), states), "Waiting to charge");
        compare(StatusText.batteryStateLabel(battery("PendingDischarge", 0.8), states), "Waiting to discharge");
        compare(StatusText.batteryStateLabel(battery("Discharging", 0.5), states), "Discharging");
        compare(StatusText.batteryStateLabel(battery("Unknown", 0.5), states), "Discharging");
    }

    function test_networkIconShowsTheFirstConnectedDevice() {
        compare(StatusText.networkIcon([
            { connected: false, wifi: true },
            { connected: true, wifi: true }
        ]), "󰤨");
        compare(StatusText.networkIcon([
            { connected: true, wifi: false },
            { connected: true, wifi: true }
        ]), "󰈀");
    }

    function test_networkIconShowsDisconnectedWithoutAConnection() {
        compare(StatusText.networkIcon([{ connected: false, wifi: true }]), "󰤭");
        compare(StatusText.networkIcon([]), "󰤭");
    }
}
