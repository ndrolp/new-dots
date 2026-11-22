import QtQuick
import QtTest
import "../modules/SettingsPlace.js" as SettingsPlace

// Where the settings panel opens: inside the capsule on a monitor whose bar
// is one, centered on any other bar.
TestCase {
    name: "SettingsPlace"

    readonly property var capsuleBar: ({ name: "capsule" })
    readonly property var opaqueBar: ({ name: "opaque" })
    readonly property var bars: [
        { window: capsuleBar, monitor: "AOC", visible: true, capsule: true, capsuleHidden: false },
        { window: opaqueBar, monitor: "Philips", visible: true, capsule: false, capsuleHidden: false }
    ]

    function test_openingOnACapsuleBarPutsItInsideThatCapsule() {
        const opened = SettingsPlace.openedOn(SettingsPlace.closed, capsuleBar, bars);
        compare(opened.where, "inside");
        compare(opened.window, capsuleBar);
    }

    function test_openingOnAnyOtherBarCentersIt() {
        const opened = SettingsPlace.openedOn(SettingsPlace.closed, opaqueBar, bars);
        compare(opened.where, "centered");
        compare(opened.window, opaqueBar);
    }

    // A real fullscreen window hides the capsule: it can't hold the panel.
    function test_openingWhileTheCapsuleIsHiddenCentersIt() {
        const hidden = [{ window: capsuleBar, monitor: "AOC", visible: true, capsule: true, capsuleHidden: true }];
        compare(SettingsPlace.openedOn(SettingsPlace.closed, capsuleBar, hidden).where, "centered");
    }

    // The settings button: opens it on its bar, closes it if it is open there.
    function test_theSettingsButtonClosesItWhenOpenOnItsBar() {
        const opened = SettingsPlace.toggledOn(SettingsPlace.closed, capsuleBar, bars);
        compare(opened.where, "inside");
        const closed = SettingsPlace.toggledOn(opened, capsuleBar, bars);
        compare(closed.where, "closed");
        compare(closed.window, capsuleBar);
    }

    function test_theSettingsButtonOnAnotherBarMovesItThere() {
        const opened = SettingsPlace.toggledOn(SettingsPlace.closed, capsuleBar, bars);
        const moved = SettingsPlace.toggledOn(opened, opaqueBar, bars);
        compare(moved.where, "centered");
        compare(moved.window, opaqueBar);
    }

    // IPC and other panels open it on the focused monitor's bar.
    function test_ipcOpensItInsideTheFocusedMonitorsCapsule() {
        const opened = SettingsPlace.toggled(SettingsPlace.closed, bars, "AOC");
        compare(opened.where, "inside");
        compare(opened.window, capsuleBar);
    }

    function test_ipcClosesItWhereverItIsOpen() {
        const opened = SettingsPlace.toggledOn(SettingsPlace.closed, opaqueBar, bars);
        const closed = SettingsPlace.toggled(opened, bars, "AOC");
        compare(closed.where, "closed");
        compare(closed.window, opaqueBar);
    }

    function test_anotherPanelOpensItOnTheFocusedMonitorsBar() {
        compare(SettingsPlace.shown(SettingsPlace.closed, bars, "AOC").where, "inside");
        compare(SettingsPlace.shown(SettingsPlace.closed, bars, "Philips").where, "centered");
    }

    // With no bar shown it opens centered on the bar it was last on.
    function test_withNoShownBarItOpensCenteredWhereItLastWas() {
        const last = { where: "closed", window: capsuleBar };
        const opened = SettingsPlace.shown(last, [], "AOC");
        compare(opened.where, "centered");
        compare(opened.window, capsuleBar);
    }
}
