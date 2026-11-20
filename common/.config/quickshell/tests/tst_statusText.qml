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

    // Quickshell gives the signal strength from 0 to 1: five steps, from no
    // bars to four, every 20%.
    function test_wifiIconHasFiveSignalSteps() {
        compare(StatusText.wifiIcon({ signalStrength: 1 }), String.fromCodePoint(0xF0928));
        compare(StatusText.wifiIcon({ signalStrength: 0.8 }), String.fromCodePoint(0xF0928));
        compare(StatusText.wifiIcon({ signalStrength: 0.79 }), String.fromCodePoint(0xF0925));
        compare(StatusText.wifiIcon({ signalStrength: 0.6 }), String.fromCodePoint(0xF0925));
        compare(StatusText.wifiIcon({ signalStrength: 0.45 }), String.fromCodePoint(0xF0922));
        compare(StatusText.wifiIcon({ signalStrength: 0.25 }), String.fromCodePoint(0xF091F));
        compare(StatusText.wifiIcon({ signalStrength: 0.1 }), String.fromCodePoint(0xF092F));
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

    // A glyph by its codepoint, so the tests name them unambiguously.
    function glyph(codepoint) {
        return String.fromCodePoint(codepoint);
    }

    // The icon shows the charge in steps of 10%, to the nearest step; at 10%
    // or less it warns.
    function test_batteryIconFollowsTheChargeInTenSteps() {
        compare(StatusText.batteryIcon(battery("Discharging", 1), states), glyph(0xF0079));
        compare(StatusText.batteryIcon(battery("Discharging", 0.96), states), glyph(0xF0079));
        compare(StatusText.batteryIcon(battery("Discharging", 0.9), states), glyph(0xF0082));
        compare(StatusText.batteryIcon(battery("Discharging", 0.72), states), glyph(0xF0080));
        compare(StatusText.batteryIcon(battery("Discharging", 0.5), states), glyph(0xF007E));
        compare(StatusText.batteryIcon(battery("Discharging", 0.2), states), glyph(0xF007B));
        compare(StatusText.batteryIcon(battery("Discharging", 0.1), states), glyph(0xF0083));
        compare(StatusText.batteryIcon(battery("Discharging", 0.03), states), glyph(0xF0083));
    }

    // Charging, it still shows how full it is, with the charging bolt.
    function test_batteryIconShowsTheChargeWhileCharging() {
        compare(StatusText.batteryIcon(battery("Charging", 0.05), states), glyph(0xF089C));
        compare(StatusText.batteryIcon(battery("Charging", 0.1), states), glyph(0xF089C));
        compare(StatusText.batteryIcon(battery("Charging", 0.5), states), glyph(0xF089D));
        compare(StatusText.batteryIcon(battery("Charging", 0.72), states), glyph(0xF089E));
        compare(StatusText.batteryIcon(battery("PendingCharge", 0.9), states), glyph(0xF008B));
        compare(StatusText.batteryIcon(battery("Charging", 1), states), glyph(0xF0085));
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

    // The first connected device decides it: Wi-Fi shows its network's
    // signal, a cable the cable.
    function test_networkIconShowsTheFirstConnectedDevice() {
        compare(StatusText.networkIcon([
            { connected: false, wifi: true, signalStrength: 1 },
            { connected: true, wifi: true, signalStrength: 0.5 }
        ]), String.fromCodePoint(0xF0922));
        compare(StatusText.networkIcon([
            { connected: true, wifi: false },
            { connected: true, wifi: true, signalStrength: 1 }
        ]), "󰈀");
    }

    function test_networkIconFollowsTheWifiSignal() {
        compare(StatusText.networkIcon([{ connected: true, wifi: true, signalStrength: 0.9 }]),
            String.fromCodePoint(0xF0928));
        compare(StatusText.networkIcon([{ connected: true, wifi: true, signalStrength: 0.3 }]),
            String.fromCodePoint(0xF091F));
    }

    function test_networkIconShowsDisconnectedWithoutAConnection() {
        compare(StatusText.networkIcon([{ connected: false, wifi: true }]), "󰤭");
        compare(StatusText.networkIcon([]), "󰤭");
    }

    function test_aSideBarValueBreaksAtEachPart() {
        compare(StatusText.sideBarValue("12:34"), "12\n34");
        compare(StatusText.sideBarValue("1:02:03"), "1\n02\n03");
        compare(StatusText.sideBarValue("󰔟  25:00"), "󰔟\n25\n00");
        compare(StatusText.sideBarValue("󰍛 12%"), "󰍛\n12");
    }

    function test_aSideBarValueLeavesOutThePercentSign() {
        compare(StatusText.sideBarValue("100%"), "100");
        compare(StatusText.sideBarValue("56°"), "56°");
    }

    function test_anEmptySideBarValueStaysEmpty() {
        compare(StatusText.sideBarValue(""), "");
    }

    function test_theClosedTrayPointsWhereItsPopupOpens_data() {
        return [
            { tag: "top", icon: "\u{f0b26}" },
            { tag: "bottom", icon: "\u{f0b2c}" },
            { tag: "left", icon: "\u{f0b2a}" },
            { tag: "right", icon: "\u{f0b28}" }
        ];
    }

    function test_theClosedTrayPointsWhereItsPopupOpens(data) {
        compare(StatusText.trayIcon(data.tag, false), data.icon);
    }

    function test_theOpenTrayPointsBackAtTheBar_data() {
        return [
            { tag: "top", icon: "\u{f0b2c}" },
            { tag: "bottom", icon: "\u{f0b26}" },
            { tag: "left", icon: "\u{f0b28}" },
            { tag: "right", icon: "\u{f0b2a}" }
        ];
    }

    function test_theOpenTrayPointsBackAtTheBar(data) {
        compare(StatusText.trayIcon(data.tag, true), data.icon);
    }
}
