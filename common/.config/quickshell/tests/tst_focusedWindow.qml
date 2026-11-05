import QtQuick
import QtTest
import "../components/FocusedWindow.js" as FocusedWindow

// The focused window as the bar elements that follow it (CurrentApp, the
// app menu) see it.
TestCase {
    name: "FocusedWindow"

    // Hyprland's active window counts only while it is on the focused
    // workspace.
    function test_theFocusedWindowIsTheActiveOneOnTheFocusedWorkspace() {
        const window = { workspace: { id: 3 } };

        compare(FocusedWindow.focusedWindow(window, { id: 3 }), window);
        compare(FocusedWindow.focusedWindow(window, { id: 4 }), null);
        compare(FocusedWindow.focusedWindow({ workspace: null }, { id: 3 }), null);
        compare(FocusedWindow.focusedWindow(null, { id: 3 }), null);
        compare(FocusedWindow.focusedWindow(window, null), null);
    }

    // They show only on the bar of the monitor whose workspace is focused.
    function test_aBarIsOnTheFocusedMonitorWhenItsMonitorHasTheFocusedWorkspace() {
        const focusedWorkspace = { id: 3, monitor: { name: "DP-1" } };

        compare(FocusedWindow.onFocusedMonitor({ name: "DP-1" }, focusedWorkspace), true);
        compare(FocusedWindow.onFocusedMonitor({ name: "HDMI-A-1" }, focusedWorkspace), false);
        compare(FocusedWindow.onFocusedMonitor(null, focusedWorkspace), false);
        compare(FocusedWindow.onFocusedMonitor({ name: "DP-1" }, null), false);
        compare(FocusedWindow.onFocusedMonitor({ name: "DP-1" }, { id: 3, monitor: null }), false);
    }
}
