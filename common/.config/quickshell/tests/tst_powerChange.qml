import QtQuick
import QtTest
import "../services/PowerChange.js" as PowerChange
import "../components/panels/OsdChange.js" as OsdChange

// The power change events: plugging the charger in or out, and the battery
// reaching 15% while discharging, read from UPower's display device. The
// first reading is how it already was, not a change.
TestCase {
    name: "PowerChange"

    // UPower's UPowerDeviceState, as plain values.
    readonly property var states: ({
        Unknown: 0, Charging: 1, Discharging: 2, Empty: 3,
        FullyCharged: 4, PendingCharge: 5, PendingDischarge: 6
    })

    function battery(state, percentage) {
        return PowerChange.reading({ isPresent: true, state: state, percentage: percentage }, states);
    }

    // Feeds `readings` in order, from the shell starting, and returns the
    // event each made (null for none).
    function events(readings) {
        let state = null;
        return readings.map(reading => {
            const next = PowerChange.next(state, reading);
            state = next.state;
            return next.event;
        });
    }

    function test_theFirstReadingShowsNothing_data() {
        return [
            { tag: "charging", reading: battery(states.Charging, 0.64) },
            { tag: "on battery", reading: battery(states.Discharging, 0.64) },
            { tag: "already low", reading: battery(states.Discharging, 0.1) }
        ];
    }

    function test_theFirstReadingShowsNothing(data) {
        compare(events([data.reading]), [null]);
    }

    function test_pluggingInShowsCharging() {
        compare(events([battery(states.Discharging, 0.64), battery(states.Charging, 0.64)]),
            [null, { kind: "charging", percentage: 0.64 }]);
    }

    function test_unpluggingShowsOnBattery() {
        compare(events([battery(states.Charging, 0.64), battery(states.Discharging, 0.64)]),
            [null, { kind: "battery", percentage: 0.64 }]);
    }

    // Charging, waiting to charge or full are all plugged in: moving between
    // them is no change.
    function test_movingBetweenPluggedInStatesShowsNothing() {
        compare(events([battery(states.Charging, 0.99), battery(states.FullyCharged, 1),
            battery(states.PendingCharge, 1), battery(states.Charging, 0.98)]),
            [null, null, null, null]);
    }

    function test_theChargeMovingShowsNothing() {
        compare(events([battery(states.Discharging, 0.64), battery(states.Discharging, 0.63),
            battery(states.Charging, 0.63), battery(states.Charging, 0.7)]),
            [null, null, { kind: "charging", percentage: 0.63 }, null]);
    }

    // An unknown state says nothing about the charger.
    function test_anUnknownStateShowsNothing() {
        compare(events([battery(states.Discharging, 0.64), battery(states.Unknown, 0.64),
            battery(states.Discharging, 0.64)]),
            [null, null, null]);
    }

    // Reaching 15% while discharging shows once, and again only after it has
    // been above 15% or plugged in, like the low-battery notification.
    function test_reachingFifteenPercentWhileDischargingShowsBatteryLowOnce() {
        compare(events([battery(states.Discharging, 0.16), battery(states.Discharging, 0.15),
            battery(states.Discharging, 0.14), battery(states.Discharging, 0.13)]),
            [null, { kind: "low", percentage: 0.15 }, null, null]);
    }

    function test_batteryLowShowsAgainOnceItHasBeenAbove() {
        compare(events([battery(states.Discharging, 0.15), battery(states.Charging, 0.15),
            battery(states.Charging, 0.2), battery(states.Discharging, 0.2),
            battery(states.Discharging, 0.15)]),
            [null, { kind: "charging", percentage: 0.15 }, null,
                { kind: "battery", percentage: 0.2 }, { kind: "low", percentage: 0.15 }]);
    }

    // Started low, it's already shown: it shows again only once re-armed.
    function test_startedLowItShowsOnlyOnceRearmed() {
        compare(events([battery(states.Discharging, 0.1), battery(states.Discharging, 0.09)]),
            [null, null]);
    }

    // Unplugging at or under 15% is reaching it while discharging: it says
    // so, once, rather than "On battery".
    function test_unpluggingLowShowsBatteryLow() {
        compare(events([battery(states.Charging, 0.12), battery(states.Discharging, 0.12),
            battery(states.Discharging, 0.11)]),
            [null, { kind: "low", percentage: 0.12 }, null]);
    }

    // Without a battery nothing ever shows.
    function test_withoutABatteryNothingShows() {
        const none = PowerChange.reading(null, states);
        const absent = PowerChange.reading({ isPresent: false, state: states.Unknown, percentage: 0 }, states);

        compare(events([none, absent, none]), [null, null, null]);
    }

    // A battery that appears is its first reading, not a change.
    function test_aBatteryAppearingShowsNothing() {
        compare(events([PowerChange.reading(null, states), battery(states.Charging, 0.5),
            battery(states.Discharging, 0.5)]),
            [null, null, { kind: "battery", percentage: 0.5 }]);
    }

    // What each shows, in the OSD and the capsule alike: the battery's icon
    // and its level in the label, no level bar.
    function test_eachPowerChangeShowsItsIconAndLabel_data() {
        return [
            { tag: "charging", event: { kind: "charging", percentage: 0.64 },
                shown: { icon: String.fromCodePoint(0xF0089), tone: "accent", label: "Charging · 64%",
                    level: null, highlighted: false, compact: true } },
            { tag: "on battery", event: { kind: "battery", percentage: 0.64 },
                shown: { icon: String.fromCodePoint(0xF007F), tone: "muted", label: "On battery · 64%",
                    level: null, highlighted: false, compact: true } },
            { tag: "battery low", event: { kind: "low", percentage: 0.15 },
                shown: { icon: String.fromCodePoint(0xF0083), tone: "warning", label: "Battery low · 15%",
                    level: null, highlighted: true, compact: true } }
        ];
    }

    function test_eachPowerChangeShowsItsIconAndLabel(data) {
        const change = OsdChange.power(data.event);
        const display = OsdChange.display(change);

        compare(change.kind, "power");
        compare({
            icon: display.icon,
            tone: display.tone,
            label: display.label,
            level: display.level,
            highlighted: display.highlighted,
            compact: display.compact
        }, data.shown);
    }
}
