import QtQuick
import QtTest
import "../components/bar/CapsuleGlance.js" as CapsuleGlance

// The capsule glance: which glance cards a capsule shows under its expanded
// row, what each says, when the glance shows and which bar elements leave
// the expanded row while it does.
TestCase {
    name: "CapsuleGlance"

    // UPower's UPowerDeviceState, as plain numbers.
    readonly property var states: ({
        Unknown: 0, Charging: 1, Discharging: 2, Empty: 3, FullyCharged: 4,
        PendingCharge: 5, PendingDischarge: 6
    })
    readonly property var wifi: ({ connected: true, wifi: true, signalStrength: 0.72, name: "Home" })
    readonly property var wired: ({ connected: true, wifi: false, signalStrength: 0, name: "" })

    function battery(fields) {
        return Object.assign({ isPresent: true, percentage: 0.84, state: states.Discharging,
            timeToEmpty: 12000, timeToFull: 0 }, fields);
    }

    function card(cards, id) {
        return cards.find(candidate => candidate.id === id);
    }

    // Battery, then Wi-Fi, each with the bar element whose popup it opens.
    function test_theCardsAreBatteryThenWifi() {
        const cards = CapsuleGlance.cards({ battery: battery({}), networks: [wifi] }, states);

        compare(cards.map(card => card.id), ["battery", "network"]);
        compare(cards.map(card => card.element), ["battery", "network"]);
        compare(cards.map(card => card.popup), ["battery", "network"]);
    }

    // The battery card: a ring with the level, the percentage, and charging,
    // the time left or full.
    function test_theBatteryCardSaysHowItIs_data() {
        return [
            { tag: "discharging", battery: { state: 2, timeToEmpty: 12000 }, text: "3 h 20 m left" },
            { tag: "under an hour", battery: { state: 2, timeToEmpty: 2700 }, text: "45 m left" },
            { tag: "charging", battery: { state: 1 }, text: "Charging" },
            { tag: "pending charge", battery: { state: 5 }, text: "Charging" },
            { tag: "full", battery: { state: 4, percentage: 1 }, text: "Full" },
            { tag: "time unknown", battery: { state: 2, timeToEmpty: 0 }, text: "On battery" }
        ];
    }

    function test_theBatteryCardSaysHowItIs(data) {
        const shown = card(CapsuleGlance.cards({ battery: battery(data.battery), networks: [] }, states),
            "battery");

        compare(shown.ring, data.battery.percentage === undefined ? 0.84 : data.battery.percentage);
        compare(shown.title, data.battery.percentage === 1 ? "100%" : "84%");
        compare(shown.text, data.text);
    }

    // The Wi-Fi card: a ring with the signal and the network's name, or
    // Ethernet, or Offline; the first connected device decides it.
    function test_theWifiCardSaysHowItIs_data() {
        return [
            { tag: "wifi", networks: [wifi], ring: 0.72, title: "Home" },
            { tag: "ethernet", networks: [wired], ring: 1, title: "Ethernet" },
            { tag: "first connected", networks: [{ connected: false, wifi: true }, wired, wifi], ring: 1,
                title: "Ethernet" },
            { tag: "offline", networks: [{ connected: false, wifi: true }], ring: 0, title: "Offline" },
            { tag: "no devices", networks: [], ring: 0, title: "Offline" }
        ];
    }

    function test_theWifiCardSaysHowItIs(data) {
        const shown = card(CapsuleGlance.cards({ battery: null, networks: data.networks }, states), "network");

        compare(shown.ring, data.ring);
        compare(shown.title, data.title);
    }

    // A card with nothing to show isn't there: no battery, no battery card.
    function test_aCardWithNothingToShowIsAbsent_data() {
        return [
            { tag: "no battery", battery: null },
            { tag: "not present", battery: { isPresent: false } }
        ];
    }

    function test_aCardWithNothingToShowIsAbsent(data) {
        const given = data.battery === null ? null : battery(data.battery);
        const cards = CapsuleGlance.cards({ battery: given, networks: [wifi] }, states);

        compare(cards.map(card => card.id), ["network"]);
    }

    readonly property var someCards: CapsuleGlance.cards({ battery: battery({}), networks: [wifi] }, states)

    // The glance shows under the expanded row, from hovering or SUPER+I:
    // not at rest, not for a change event, not with a popup inside the
    // capsule, and not without a card.
    function test_theGlanceShowsOnlyUnderTheExpandedRow_data() {
        return [
            { tag: "expanded", view: "expanded", popupInside: false, cards: someCards, shown: true },
            { tag: "at rest", view: "rest", popupInside: false, cards: someCards, shown: false },
            { tag: "a change", view: "change", popupInside: false, cards: someCards, shown: false },
            { tag: "a popup inside", view: "expanded", popupInside: true, cards: someCards, shown: false },
            { tag: "no cards", view: "expanded", popupInside: false, cards: [], shown: false }
        ];
    }

    function test_theGlanceShowsOnlyUnderTheExpandedRow(data) {
        compare(CapsuleGlance.shown({ view: data.view, popupInside: data.popupInside, cards: data.cards }),
            data.shown);
    }

    // While the glance shows, each card's bar element leaves the expanded
    // row; without the glance, none does.
    function test_theCardsElementsLeaveTheRow_data() {
        return [
            { tag: "both", cards: someCards, shown: true, leaving: ["battery", "network"] },
            { tag: "no battery", cards: CapsuleGlance.cards({ battery: null, networks: [wifi] }, states),
                shown: true, leaving: ["network"] },
            { tag: "no glance", cards: someCards, shown: false, leaving: [] }
        ];
    }

    function test_theCardsElementsLeaveTheRow(data) {
        compare(CapsuleGlance.leavingElements(data.cards, data.shown), data.leaving);
    }
}
