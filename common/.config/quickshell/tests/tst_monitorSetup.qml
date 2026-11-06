import QtQuick
import QtTest
import "../services/MonitorSetup.js" as MonitorSetup

// What a monitor setup holds, how Displays and the quick switch change one, and the saved file.
TestCase {
    name: "MonitorSetup"

    readonly property string laptop: "Samsung Display Corp. ATNA40HQ01-0"
    readonly property string aoc: "AOC Q27G42XE 2S6S1HA031479"

    // Shaped like `hyprctl monitors all -j`.
    function live(name, description, fields) {
        return Object.assign({
            id: name === "eDP-1" ? 0 : 1,
            name: name,
            description: description,
            model: description.split(" ")[0],
            width: 2880,
            height: 1800,
            refreshRate: 120.0,
            x: 0,
            y: 0,
            scale: 1.6,
            transform: 0,
            disabled: false,
            mirrorOf: "none",
            currentFormat: "XRGB8888",
            availableModes: ["2880x1800@120.00Hz", "2880x1800@60.00Hz"]
        }, fields || {});
    }

    readonly property var aocModes: ["2560x1440@143.91Hz", "2560x1440@59.95Hz", "1920x1080@100.00Hz", "1366x768@60.00Hz"]

    function docked() {
        return [
            live("eDP-1", laptop),
            live("DP-2", aoc, { x: 1800, width: 2560, height: 1440, refreshRate: 143.912, scale: 1,
                availableModes: aocModes })
        ];
    }

    function entries() {
        return MonitorSetup.entriesFrom(docked(), [], false);
    }

    function entry(list, port) {
        return list.filter(item => item.port === port)[0];
    }

    function modes(port) {
        return MonitorSetup.modesOf(docked(), port);
    }

    function test_aLiveMonitorBecomesAnEntryInTheSavedFormat() {
        const aocEntry = entry(entries(), "DP-2");
        compare(aocEntry.description, aoc);
        compare(aocEntry.mode, "2560x1440@143.91");
        compare(aocEntry.position, "1800x0");
        compare(aocEntry.scale, 1);
        compare(aocEntry.transform, 0);
        compare(aocEntry.disabled, false);
        compare(aocEntry.mirror, "");
    }

    function test_fieldsWithNoControlAreKeptFromTheSavedEntry() {
        const saved = [{ description: aoc, port: "DP-2", vrr: 1, bitdepth: 10, cm: "hdr" }];
        const aocEntry = entry(MonitorSetup.entriesFrom(docked(), saved, false), "DP-2");
        compare(aocEntry.vrr, 1);
        compare(aocEntry.bitdepth, 10);
        compare(aocEntry.cm, "hdr");
        compare(aocEntry.position, "1800x0");
    }

    function test_aTenBitMonitorStaysTenBit() {
        const monitors = [live("DP-2", aoc, { currentFormat: "XRGB2101010" })];
        compare(MonitorSetup.entriesFrom(monitors, [], false)[0].bitdepth, 10);
    }

    function test_aMonitorThatIsOffKeepsItsSavedMode() {
        const saved = [{ description: laptop, port: "eDP-1", mode: "2880x1800@60.00", position: "0x0", scale: 2 }];
        const monitors = [live("eDP-1", laptop, { disabled: true, width: 0, height: 0 }), docked()[1]];
        const laptopEntry = entry(MonitorSetup.entriesFrom(monitors, saved, false), "eDP-1");
        compare(laptopEntry.disabled, true);
        compare(laptopEntry.mode, "2880x1800@60.00");
        compare(laptopEntry.scale, 2);
    }

    function test_aMirrorNamesTheMonitorItCopiesByDescription() {
        const monitors = docked();
        monitors[1].mirrorOf = "0";
        compare(entry(MonitorSetup.entriesFrom(monitors, [], false), "DP-2").mirror, laptop);
    }

    function test_aMirrorBetweenIdenticalMonitorsNamesThePort() {
        const monitors = [live("DP-1", aoc, { id: 4 }), live("DP-2", aoc, { id: 5, mirrorOf: "4" })];
        compare(entry(MonitorSetup.entriesFrom(monitors, [], false), "DP-2").mirror, "DP-1");
    }

    // The same rule as split_by_lid in hypr/modules/monitors/setups.lua: a setup with the laptop in
    // it would never match a closed lid's combination.
    function test_aClosedLidLeavesTheLaptopOutWithAnExternalMonitor() {
        const list = MonitorSetup.entriesFrom(docked(), [], true);
        compare(list.map(item => item.port), ["DP-2"]);
    }

    function test_aClosedLidCountsForNothingWithNoExternalMonitor() {
        const list = MonitorSetup.entriesFrom([live("eDP-1", laptop)], [], true);
        compare(list.map(item => item.port), ["eDP-1"]);
    }

    function test_aReadingSaysTheLidAndTheMonitors() {
        const reading = MonitorSetup.parsedReading('state:      closed\n[{"name": "DP-2"}]\n');
        compare(reading.lidClosed, true);
        compare(reading.monitors[0].name, "DP-2");
    }

    function test_aMachineWithNoLidReadsAsOpen() {
        const reading = MonitorSetup.parsedReading('[{"name": "DP-2"}]');
        compare(reading.lidClosed, false);
        compare(reading.monitors.length, 1);
    }

    function test_aReadingThatMakesNoSenseIsNoReading() {
        compare(MonitorSetup.parsedReading("Couldn't connect"), null);
    }

    function test_rectanglesAreLogicalPixels() {
        const rects = MonitorSetup.rectangles(entries());
        compare(rects[0].width, 1800);
        compare(rects[0].height, 1125);
    }

    // scripts/import-monitor-setups keeps what the old config said, which isn't always a number.
    function imported(fields) {
        return Object.assign({ description: "Imported", port: "DP-3", mode: "1000x800@60.00", position: "auto-left",
            scale: 1, transform: 0, disabled: false, mirror: "" }, fields);
    }

    function test_aPositionThatIsNoNumberSitsPastTheOthersOnTheCanvas() {
        const rects = MonitorSetup.rectangles(entries().concat([imported({})]));
        const rect = rects.filter(item => item.id === "DP-3")[0];
        compare([rect.x, rect.y], [4360, 0]);
    }

    function test_severalPositionsThatAreNoNumberDontStack() {
        const rects = MonitorSetup.rectangles([imported({ position: "auto" }),
            imported({ port: "DP-4", position: "auto-right" })]);
        compare(rects.map(rect => rect.x), [0, 1000]);
    }

    function test_aScaleThatIsNoNumberCountsAsOne() {
        const rect = MonitorSetup.rectangles([imported({ scale: "auto" })])[0];
        compare([rect.width, rect.height], [1000, 800]);
    }

    function test_anyChangeGivesAPositionThatIsNoNumberARealOne() {
        const list = entries().concat([imported({})]);
        compare(entry(MonitorSetup.moved(list, "eDP-1", 0, 0), "DP-3").position, "4360x0");
    }

    function test_turningOnAMonitorSavedOnlyAsPreferredTakesItsHighest() {
        const list = entries();
        Object.assign(entry(list, "eDP-1"), { disabled: true, mode: "preferred", position: "auto-left",
            scale: "auto" });
        const on = entry(MonitorSetup.turnedOn(list, "eDP-1", modes("eDP-1")), "eDP-1");
        compare(on.mode, "2880x1800@120.00");
        compare(on.position, "2560x0");
        compare(on.scale, 1);
    }

    function test_aTurnedMonitorSwapsItsSides() {
        const turned = MonitorSetup.withRotation(entries(), "DP-2", 1);
        const rect = MonitorSetup.rectangles(turned).filter(item => item.id === "DP-2")[0];
        compare([rect.width, rect.height], [1440, 2560]);
    }

    function test_movingAMonitorSnapsItAndWritesItsPosition() {
        const moved = MonitorSetup.moved(entries(), "DP-2", 0, 1200);
        compare(entry(moved, "DP-2").position, "0x1125");
        compare(entry(moved, "eDP-1").position, "0x0");
    }

    function test_changingResolutionFollowsTheRefreshRules() {
        const changed = MonitorSetup.withResolution(entries(), "DP-2", modes("DP-2"), 1920, 1080);
        compare(entry(changed, "DP-2").mode, "1920x1080@100.00");
    }

    function test_turningAMonitorClosesTheGapItLeaves() {
        const list = MonitorSetup.withRotation(entries(), "eDP-1", 1);
        compare(entry(list, "DP-2").position, "1125x0");
    }

    function test_changingResolutionKeepsTheScaleHyprlandCanUse() {
        const list = MonitorSetup.withScale(entries(), "DP-2", 1.25);
        const changed = MonitorSetup.withResolution(list, "DP-2", modes("DP-2"), 1366, 768);
        compare(entry(changed, "DP-2").scale, 1);
    }

    function test_choosingARateKeepsTheResolution() {
        compare(entry(MonitorSetup.withRefresh(entries(), "DP-2", 59.95), "DP-2").mode, "2560x1440@59.95");
    }

    function test_aScaleHyprlandWontAcceptSnapsAndTheEntryHoldsWhatApplies() {
        compare(entry(MonitorSetup.withScale(entries(), "DP-2", 1.75), "DP-2").scale, 200 / 120);
    }

    function test_turningAMonitorOffClosesTheGap() {
        const row = entries().concat([{ description: "Third", port: "DP-3", mode: "1000x800@60.00",
            position: "4360x0", scale: 1, transform: 0, disabled: false, mirror: "" }]);
        const off = MonitorSetup.turnedOff(row, "DP-2");
        compare(entry(off, "DP-2").disabled, true);
        compare(entry(off, "DP-3").position, "1800x0");
    }

    function test_theLastMonitorCantBeTurnedOff() {
        const off = MonitorSetup.turnedOff(entries(), "DP-2");
        compare(MonitorSetup.canTurnOff(off, "eDP-1"), false);
        compare(entry(MonitorSetup.turnedOff(off, "eDP-1"), "eDP-1").disabled, false);
    }

    function test_aMirrorOfTheMonitorTurnedOffGetsItsOwnPicture() {
        const list = entries();
        entry(list, "DP-2").mirror = laptop;
        const off = MonitorSetup.turnedOff(list, "eDP-1");
        compare(entry(off, "eDP-1").disabled, true);
        compare(entry(off, "DP-2").mirror, "");
        compare(MonitorSetup.showsSomething(off), true);
    }

    function test_turningAMonitorOnPutsItPastTheOthers() {
        const off = MonitorSetup.turnedOff(entries(), "eDP-1");
        const on = MonitorSetup.turnedOn(off, "eDP-1", modes("eDP-1"));
        compare(entry(on, "eDP-1").disabled, false);
        compare(entry(on, "eDP-1").position, "2560x0");
    }

    function test_turningOnAMonitorThatNeverHadAModeTakesItsHighest() {
        const list = entries();
        delete entry(list, "eDP-1").mode;
        entry(list, "eDP-1").disabled = true;
        const on = MonitorSetup.turnedOn(list, "eDP-1", modes("eDP-1"));
        compare(entry(on, "eDP-1").mode, "2880x1800@120.00");
    }

    function test_aSetupWithEveryMonitorOffShowsNothing() {
        const list = entries();
        list.forEach(item => item.disabled = true);
        compare(MonitorSetup.showsSomething(list), false);
    }

    function test_monitorsOnlyMirroringEachOtherShowNothing() {
        const list = entries();
        entry(list, "DP-2").mirror = laptop;
        entry(list, "eDP-1").mirror = aoc;
        compare(MonitorSetup.showsSomething(list), false);
    }

    function test_aCombinationDoesntDependOnPortOrOrder() {
        compare(MonitorSetup.combination([{ description: "b", port: "1" }, { description: "a", port: "2" }]),
            MonitorSetup.combination([{ description: "a", port: "7" }, { description: "b", port: "8" }]));
    }

    function test_aMissingFileIsAFileWithNoSetups() {
        compare(MonitorSetup.parsedFile(null).setups, []);
    }

    function test_aFileThatCantBeReadIsNotTreatedAsEmpty() {
        compare(MonitorSetup.parsedFile("{ not json"), null);
        compare(MonitorSetup.parsedFile('{"setups": 3}'), null);
    }

    function test_savingKeepsTheOtherCombinationsSetups() {
        const other = { monitors: [{ description: laptop, port: "eDP-1" }] };
        const data = MonitorSetup.withSetup({ setups: [other] }, entries());
        compare(data.setups.length, 2);
        compare(data.setups[0].monitors[0].description, laptop);
    }

    function test_savingReplacesTheSetupOfTheSameCombination() {
        const old = { monitors: [{ description: aoc, port: "DP-9" }, { description: laptop, port: "eDP-1" }] };
        const data = MonitorSetup.withSetup({ setups: [old] }, entries());
        compare(data.setups.length, 1);
        compare(entry(data.setups[0].monitors, "DP-2").position, "1800x0");
    }

    function test_theSavedEntriesOfACombinationAreFound() {
        const old = { monitors: [{ description: aoc, port: "DP-2", vrr: 2 }] };
        compare(MonitorSetup.savedEntries({ setups: [old] }, [live("DP-2", aoc)])[0].vrr, 2);
        compare(MonitorSetup.savedEntries({ setups: [] }, [live("DP-2", aoc)]), []);
    }

    function test_savedSetupsAreListedNamedAfterTheirMonitors() {
        const data = { setups: [{ monitors: [{ description: "AOC" }, { description: "Samsung" }] }] };
        compare(MonitorSetup.listedSetups(data)[0].name, "AOC + Samsung");
        compare(MonitorSetup.listedSetups(data)[0].monitors.length, 2);
        compare(MonitorSetup.listedSetups(data)[0].combination, "AOC\nSamsung");
    }

    function test_entriesThatMatchAreTheSameArrangement() {
        compare(MonitorSetup.sameEntries(entries(), entries()), true);
        compare(MonitorSetup.sameEntries(entries(), MonitorSetup.withRefresh(entries(), "DP-2", 59.95)), false);
    }
}
