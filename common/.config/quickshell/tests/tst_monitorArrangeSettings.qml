import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../services/MonitorChange.js" as MonitorChange
import "../services/MonitorSetup.js" as MonitorSetup

// The Displays section: the arrange canvas, the selected monitor's controls and the countdown card.
Item {
    id: scene

    width: 800
    height: 900

    TestCase {
        id: test

        name: "MonitorArrangeSettings"
        when: windowShown

        Config.Theme {
            id: theme
        }

        function all(item, predicate, found) {
            found = found || [];
            if (predicate(item))
                found.push(item);
            for (let i = 0; i < item.children.length; i++)
                all(item.children[i], predicate, found);
            return found;
        }

        function shown(item, text) {
            return all(item, child => child.text === text && child.font !== undefined && child.visible)[0] || null;
        }

        function containing(item, text) {
            return all(item, child => typeof child.text === "string" && child.font !== undefined
                && child.visible && child.text.indexOf(text) !== -1)[0] || null;
        }

        // Selecting rebuilds the chips, which sit on top of each other until Flow lays them out.
        function select(section, id) {
            mouseClick(monitorOnCanvas(section, id));
            waitForRendering(section);
        }

        function monitorOnCanvas(section, id) {
            return all(section, child => child.monitorId === id)[0];
        }

        function entries() {
            return [
                { description: "Samsung", port: "eDP-1", mode: "2880x1800@120.00", position: "0x0", scale: 1.6,
                    transform: 0, disabled: false, mirror: "" },
                { description: "AOC", port: "DP-2", mode: "2560x1440@143.91", position: "1800x0", scale: 1,
                    transform: 0, disabled: false, mirror: "" }
            ];
        }

        // Stands in for services/MonitorSetups.qml and records what's asked of it.
        Component {
            id: fakeSetups

            QtObject {
                property var entries: test.entries()
                property var applied: []
                property int identified: 0
                property bool refuses: false
                property bool counting: false
                property var forgot: []
                property var savedSetups: [
                    { combination: "AOC\nPhilips", name: "AOC + Philips", monitors: [] },
                    { combination: "Samsung", name: "Samsung", monitors: [] }
                ]

                function forget(combination) {
                    forgot = forgot.concat([combination]);
                    savedSetups = savedSetups.filter(setup => setup.combination !== combination);
                    return true;
                }

                function modesOf(port) {
                    return port === "DP-2"
                        ? [{ width: 2560, height: 1440, refresh: 143.91 }, { width: 2560, height: 1440, refresh: 59.95 },
                            { width: 1920, height: 1080, refresh: 100 }]
                        : [{ width: 2880, height: 1800, refresh: 120 }, { width: 2880, height: 1800, refresh: 60 }];
                }

                function apply(next) {
                    if (refuses)
                        return false;
                    applied = applied.concat([next]);
                    entries = next;
                    return true;
                }

                function identify() {
                    identified++;
                }
            }
        }

        QtObject {
            id: fakeMonitors

            function rangeFor(description) {
                return { from: 1, to: 5 };
            }

            function displaySettingsFor(description) {
                return { barVisible: true, barProfile: "default" };
            }
        }

        QtObject {
            id: fakeAppearance

            property int radius: 8
            property int textSize: 13
            property var motion: ({ short: 0, easing: Easing.OutCubic })
            property var barProfiles: ({})
        }

        Component {
            id: sectionComponent

            Panels.MonitorArrangeSettings {
                width: 760
            }
        }

        function section() {
            const setups = createTemporaryObject(fakeSetups, scene);
            const item = createTemporaryObject(sectionComponent, scene, {
                appearance: fakeAppearance,
                monitors: fakeMonitors,
                monitorSetups: setups
            });
            waitForRendering(item);
            return item;
        }

        function test_monitorsAreDrawnToScale() {
            const item = section();
            const laptop = monitorOnCanvas(item, "eDP-1");
            const aoc = monitorOnCanvas(item, "DP-2");
            fuzzyCompare(aoc.width / laptop.width, 2560 / 1800, 0.02);
            fuzzyCompare(aoc.height / laptop.height, 1440 / 1125, 0.02);
        }

        function test_monitorsStayInsideTheCanvas() {
            const item = section();
            const canvas = monitorOnCanvas(item, "DP-2").parent;
            verify(monitorOnCanvas(item, "DP-2").x + monitorOnCanvas(item, "DP-2").width <= canvas.width);
        }

        function test_droppingAMonitorAppliesTheSnappedSetup() {
            const item = section();
            const aoc = monitorOnCanvas(item, "DP-2");
            mouseDrag(aoc, aoc.width / 2, aoc.height / 2, -aoc.x, 150);
            tryCompare(item.monitorSetups.applied, "length", 1);
            const moved = item.monitorSetups.applied[0].filter(entry => entry.port === "DP-2")[0];
            const rects = MonitorSetup.rectangles(item.monitorSetups.applied[0]);
            compare(moved.position.split("x")[1] !== "0", true);
            compare(rects.length, 2);
        }

        function test_aMonitorGoesBackIfItsSetupIsRefused() {
            const item = section();
            item.monitorSetups.refuses = true;
            const aoc = monitorOnCanvas(item, "DP-2");
            const startX = aoc.x;
            mouseDrag(aoc, aoc.width / 2, aoc.height / 2, -40, 150);
            tryCompare(aoc, "x", startX);
        }

        function test_aTapSelectsWithoutChangingAnything() {
            const item = section();
            const aoc = monitorOnCanvas(item, "DP-2");
            mouseClick(aoc);
            compare(item.selected.port, "DP-2");
            compare(item.monitorSetups.applied.length, 0);
        }

        function test_theFirstMonitorStartsSelected() {
            compare(section().selected.port, "eDP-1");
        }

        function test_theSelectedMonitorShowsItsControlsThenItsWorkspaceAndBarSettings() {
            const item = section();
            const aoc = monitorOnCanvas(item, "DP-2");
            mouseClick(aoc);
            verify(shown(item, "Resolution") !== null);
            verify(shown(item, "Refresh rate") !== null);
            verify(shown(item, "Scale") !== null);
            verify(shown(item, "Rotation") !== null);
            verify(shown(item, "First workspace") !== null);
            verify(shown(item, "Bar profile") !== null);
            verify(shown(item, "1920x1080") !== null);
        }

        function test_theRefreshListFollowsTheChosenResolution() {
            const item = section();
            select(item, "DP-2");
            verify(shown(item, "59.95 Hz") !== null);
            verify(shown(item, "100 Hz") === null);
            mouseClick(shown(item, "1920x1080"));
            tryVerify(() => shown(item, "100 Hz") !== null);
            compare(item.monitorSetups.entries[1].mode, "1920x1080@100.00");
        }

        function test_aScaleThatSnapsSaysWhatWasApplied() {
            const item = section();
            select(item, "DP-2");
            mouseClick(shown(item, "1.75"));
            tryVerify(() => containing(item, "1.67") !== null);
            verify(containing(item, "1.75 isn't available") !== null);
        }

        function test_rotatingAppliesTheNewTransform() {
            const item = section();
            select(item, "DP-2");
            mouseClick(shown(item, "90°"));
            compare(item.monitorSetups.applied[0][1].transform, 1);
        }

        function test_theLastMonitorCantBeTurnedOff() {
            const item = section();
            const off = entries();
            off[1].disabled = true;
            item.monitorSetups.entries = off;
            waitForRendering(item);
            const row = all(item, child => child.label === "On" && child.switchItem !== undefined)[0];
            compare(row.enabled, false);
        }

        function test_aMonitorThatIsOffCanBeChosenAndTurnedOn() {
            const item = section();
            const off = entries();
            off[1].disabled = true;
            item.monitorSetups.entries = off;
            waitForRendering(item);
            verify(monitorOnCanvas(item, "DP-2") === undefined);
            mouseClick(shown(item, "2 AOC"));
            tryCompare(item, "selectedPort", "DP-2");
            const row = all(item, child => child.label === "On" && child.switchItem !== undefined)[0];
            mouseClick(row);
            compare(item.monitorSetups.applied[0][1].disabled, false);
        }

        function test_identifyAsksTheService() {
            const item = section();
            mouseClick(shown(item, "Identify"));
            compare(item.monitorSetups.identified, 1);
        }

        // The list is below the monitor's settings, so the section moves up to bring a button into the window.
        function forgetButton(item, setupName) {
            const row = all(item, child => child.setupName === setupName)[0];
            const button = all(row, child => child.label === "Forget")[0];
            item.y = -button.mapToItem(item, 0, 0).y;
            waitForRendering(item);
            return button;
        }

        function test_eachSavedSetupIsListedByName() {
            const item = section();
            verify(shown(item, "AOC + Philips") !== null);
            verify(shown(item, "Samsung") !== null);
        }

        function test_forgetAsksTheServiceForThatSetupAndChangesNoMonitor() {
            const item = section();
            mouseClick(forgetButton(item, "AOC + Philips"));
            compare(item.monitorSetups.forgot, ["AOC\nPhilips"]);
            compare(item.monitorSetups.applied.length, 0);
            compare(shown(item, "AOC + Philips"), null);
            verify(shown(item, "Samsung") !== null);
        }

        function test_nothingCanBeForgottenDuringACountdown() {
            const item = section();
            item.monitorSetups.counting = true;
            const button = forgetButton(item, "Samsung");
            compare(button.enabled, false);
            mouseClick(button);
            compare(item.monitorSetups.forgot.length, 0);
        }

        function test_withNothingSavedTheListIsNotShown() {
            const item = section();
            verify(shown(item, "Saved setups") !== null);
            item.monitorSetups.savedSetups = [];
            compare(shown(item, "Saved setups"), null);
        }

        Component {
            id: cardComponent

            Panels.MonitorChangeCard {
                property int kept: 0
                property int reverted: 0

                onKeepAsked: kept++
                onRevertAsked: reverted++
            }
        }

        function card() {
            return createTemporaryObject(cardComponent, scene, {
                appearance: fakeAppearance, secondsLeft: 12
            });
        }

        function test_theCardSaysHowLongIsLeft() {
            verify(containing(card(), "12") !== null);
        }

        function test_theCardsButtonsAsk() {
            const item = card();
            waitForRendering(item);
            mouseClick(shown(item, "Keep"));
            mouseClick(shown(item, "Revert"));
            compare(item.kept, 1);
            compare(item.reverted, 1);
        }

        function test_enterKeeps() {
            for (const key of [Qt.Key_Return, Qt.Key_Enter]) {
                const item = card();
                item.forceActiveFocus();
                keyClick(key);
                compare(item.kept, 1);
                compare(item.reverted, 0);
            }
        }

        function test_escapeReverts() {
            const item = card();
            item.forceActiveFocus();
            keyClick(Qt.Key_Escape);
            compare(item.reverted, 1);
            compare(item.kept, 0);
        }

        function test_applyingAsksHyprlandToReadTheFile() {
            compare(MonitorChange.applyCommand[0], "hyprctl");
            verify(MonitorChange.applyCommand[2].indexOf("apply_now") !== -1);
        }

        function test_theEventsThatChangeMonitorsAreKnown() {
            compare(MonitorSetup.changesMonitors("monitoradded"), true);
            compare(MonitorSetup.changesMonitors("monitorremovedv2"), true);
            compare(MonitorSetup.changesMonitors("configreloaded"), true);
            compare(MonitorSetup.changesMonitors("workspace"), false);
        }
    }
}
