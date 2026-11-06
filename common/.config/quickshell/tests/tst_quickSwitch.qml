import QtQuick
import QtTest
import "../services/MonitorChange.js" as MonitorChange
import "../services/MonitorSetup.js" as MonitorSetup
import "../services/QuickSwitch.js" as QuickSwitch

// The quick switch's choices and the setup each one builds. The toast offers the same ones.
TestCase {
    name: "QuickSwitch"

    function entries() {
        return [
            { description: "Samsung", port: "eDP-1", mode: "2880x1800@120.00", position: "0x0", scale: 1.6,
                transform: 0, disabled: false, mirror: "" },
            { description: "AOC", port: "DP-2", mode: "2560x1440@143.91", position: "1800x0", scale: 1,
                transform: 0, disabled: false, mirror: "" }
        ];
    }

    function test_theChoicesAreExtendMirrorAndEachMonitorOnly() {
        compare(QuickSwitch.choices(entries()).map(choice => choice.label),
            ["Extend", "Mirror", "Samsung only", "AOC only"]);
    }

    function test_identicalMonitorsAreToldApartByPort() {
        const list = [{ description: "AOC", port: "DP-1" }, { description: "AOC", port: "DP-2" }];
        compare(QuickSwitch.choices(list).slice(2).map(choice => choice.label),
            ["AOC (DP-1) only", "AOC (DP-2) only"]);
    }

    function modesOf(port) {
        return port === "DP-2"
            ? [{ width: 2560, height: 1440, refresh: 143.91 }, { width: 1920, height: 1080, refresh: 60 }]
            : [{ width: 2880, height: 1800, refresh: 120 }];
    }

    function build(kind, list, port) {
        return QuickSwitch.entriesFor({ kind: kind, port: port }, list, "eDP-1", modesOf);
    }

    function entry(list, port) {
        return list.filter(item => item.port === port)[0];
    }

    function test_extendChangesNothingWhenEveryMonitorIsAlreadyOn() {
        compare(JSON.stringify(build("extend", entries())), JSON.stringify(entries()));
    }

    function test_extendTurnsEveryMonitorBackOnWhereItWas() {
        const list = entries();
        list[0].disabled = true;
        const result = build("extend", list);
        compare(entry(result, "eDP-1").disabled, false);
        compare(entry(result, "eDP-1").position, "0x0");
        compare(entry(result, "eDP-1").mode, "2880x1800@120.00");
        compare(entry(result, "DP-2").position, "1800x0");
    }

    function test_extendPutsAMonitorWithNoArrangementPastTheOthersAtItsHighestMode() {
        const list = [entries()[0], { description: "AOC", port: "DP-2", disabled: true, mirror: "" }];
        const result = build("extend", list);
        compare(entry(result, "DP-2").disabled, false);
        compare(entry(result, "DP-2").mode, "2560x1440@143.91");
        compare(entry(result, "DP-2").position, "1800x0");
        compare(entry(result, "DP-2").scale, 1);
        compare(entry(result, "DP-2").transform, 0);
    }

    function test_extendMovesMonitorsApartThatWouldOverlap() {
        const list = entries();
        list[1].position = "0x0";
        const result = build("extend", list);
        verify(entry(result, "eDP-1").position !== entry(result, "DP-2").position);
    }

    function test_extendKeepsFieldsItHasNoControlFor() {
        const list = entries();
        list[0].vrr = 1;
        compare(entry(build("extend", list), "eDP-1").vrr, 1);
    }

    function test_mirrorMakesEveryOtherMonitorCopyTheFocusedOneAtItsPreferredMode() {
        const list = entries().concat([{ description: "LG", port: "HDMI-A-1", mode: "1920x1080@60.00",
            position: "4360x0", scale: 1, transform: 0, disabled: false, mirror: "" }]);
        const result = build("mirror", list);
        compare(entry(result, "eDP-1").mirror, "");
        compare(entry(result, "eDP-1").mode, "2880x1800@120.00");
        compare(entry(result, "DP-2").mirror, "Samsung");
        compare(entry(result, "DP-2").mode, "preferred");
        compare(entry(result, "HDMI-A-1").mirror, "Samsung");
        compare(entry(result, "HDMI-A-1").mode, "preferred");
    }

    // setups.lua finds the monitor copied by port first, then by description.
    function test_mirrorNamesThePortBetweenIdenticalMonitors() {
        const list = entries();
        list[0].description = "AOC";
        compare(entry(build("mirror", list), "DP-2").mirror, "eDP-1");
    }

    function test_mirrorTurnsOnAMonitorThatWasOff() {
        const list = entries();
        list[1].disabled = true;
        compare(entry(build("mirror", list), "DP-2").disabled, false);
    }

    function test_mirrorCopiesAMonitorWithAPictureWhenTheFocusedOneHasNone() {
        const result = QuickSwitch.entriesFor({ kind: "mirror" }, entries(), "eDP-9", modesOf);
        compare(entry(result, "DP-2").mirror, "Samsung");
        compare(entry(result, "eDP-1").mirror, "");
    }

    function test_mirrorTwiceChangesNothing() {
        const once = build("mirror", entries());
        compare(JSON.stringify(build("mirror", once)), JSON.stringify(once));
    }

    function test_extendAfterMirrorRestoresTheLastArrangement() {
        const result = build("extend", build("mirror", entries()));
        compare(JSON.stringify(result), JSON.stringify(entries()));
    }

    // Reading the monitors back replaces a mirror's mode and position with what it's showing.
    function test_extendAfterMirrorIgnoresWhatAMirrorReportsOfItself() {
        const list = build("mirror", entries());
        list[1].mode = "2880x1800@60.00";
        list[1].position = "0x0";
        compare(JSON.stringify(build("extend", list)), JSON.stringify(entries()));
    }

    function test_extendGivesAMirrorWithNoLastArrangementTheAutomaticOne() {
        const list = entries();
        list[1].mirror = "Samsung";
        list[1].position = "0x0";
        const result = build("extend", list);
        compare(entry(result, "DP-2").mirror, "");
        compare(entry(result, "DP-2").mode, "2560x1440@143.91");
        compare(entry(result, "DP-2").position, "1800x0");
    }

    function test_oneMonitorOnlyTurnsTheOthersOff() {
        const result = build("only", entries(), "DP-2");
        compare(entry(result, "eDP-1").disabled, true);
        compare(entry(result, "DP-2").disabled, false);
    }

    function test_oneMonitorOnlyLeavesTheOthersWithTheirArrangementForExtend() {
        const result = build("extend", build("only", entries(), "DP-2"));
        compare(JSON.stringify(result), JSON.stringify(entries()));
    }

    function test_aMirroredMonitorOnlyGetsItsOwnPictureBack() {
        const result = build("only", build("mirror", entries()), "DP-2");
        compare(entry(result, "DP-2").mirror, "");
        compare(entry(result, "DP-2").mode, "2560x1440@143.91");
        compare(entry(result, "eDP-1").disabled, true);
    }

    function test_oneMonitorOnlyTurnsOnAMonitorThatWasOff() {
        const list = entries();
        list[1].disabled = true;
        const result = build("only", list, "DP-2");
        compare(entry(result, "DP-2").disabled, false);
        compare(entry(result, "eDP-1").disabled, true);
    }

    function test_everyChoiceLeavesSomethingToSee() {
        QuickSwitch.choices(entries()).forEach(choice => {
            const result = QuickSwitch.entriesFor(choice, entries(), "eDP-1", modesOf);
            verify(MonitorSetup.showsSomething(result), choice.label);
        });
    }

    // Keep saves what was tried, as its combination's setup; Hyprland ignores the kept arrangement.
    function test_aKeptChoiceIsSavedAsThatCombinationsSetup() {
        const trying = build("mirror", entries());
        const step = MonitorChange.kept(MonitorChange.changed(MonitorChange.idle, null, entries(), trying, 0).state);
        const data = MonitorSetup.parsedFile(step.text);
        compare(data.setups.length, 1);
        compare(MonitorSetup.combination(data.setups[0].monitors), "AOC\nSamsung");
        compare(entry(data.setups[0].monitors, "DP-2").mirror, "Samsung");
        const reread = MonitorSetup.savedEntries(data, entries());
        compare(JSON.stringify(build("extend", reread)), JSON.stringify(entries()));
    }

    function test_nextMovesDownAndWrapsAround() {
        compare(QuickSwitch.next(0, 3), 1);
        compare(QuickSwitch.next(2, 3), 0);
        compare(QuickSwitch.next(0, 0), 0);
    }

    function test_aMirroringMonitorIsToldFromOthers() {
        const list = build("mirror", entries());
        compare(QuickSwitch.mirroring(list, "DP-2"), true);
        compare(QuickSwitch.mirroring(list, "eDP-1"), false);
        compare(QuickSwitch.mirroring(list, "HDMI-A-1"), false);
    }
}
