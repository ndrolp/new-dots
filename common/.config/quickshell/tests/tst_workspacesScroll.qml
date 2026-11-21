import QtQuick
import QtTest
import "../components/bar" as Bar
import "../config/BarProfileModel.js" as BarProfileModel

// Scrolling over the bar's workspaces element goes to the next or previous
// workspace it shows on its monitor, like the capsule's pills, and stops at
// either end.
TestCase {
    name: "WorkspacesScroll"
    width: 400
    height: 100
    visible: true
    when: windowShown

    QtObject {
        id: profile

        property string barPosition: "top"
        property int barHeight: 40
        property int spacing: 4
        property int radius: 8
        property int workspaceButtonSize: 20
        property int textSize: 13
        property int activeWorkspaceHorizontalPadding: 6
        property bool pillsTransparent: false
        property string barStyle: "opaque"
        property bool elementBorder: false
        property var barElements: BarProfileModel.normalizeBarElements({
            left: [{ id: "workspaces", enabled: true, options: { hideEmpty: false } }],
            center: [], right: []
        })
        property var motion: ({ short: 0, medium: 0, long: 0, brief: 0, easing: 0 })
    }

    // Hyprland's workspaces as the workspace service shows them: 1 to 4 on
    // this monitor, 2 shown on it, 7 focused on another.
    QtObject {
        id: fakeService

        property int shownOnMonitor: 2
        property var occupied: [1, 2, 4]
        property var switchedTo: []

        function workspacesForScreen() {
            return [1, 2, 3, 4];
        }

        function monitorDescriptionForScreen() {
            return "monitor";
        }

        function activeWorkspaceIdForScreen(screen) {
            return screen === "screen" ? shownOnMonitor : -1;
        }

        function isActive(workspaceId) {
            return workspaceId === 7;
        }

        function isOccupied(workspaceId) {
            return occupied.indexOf(workspaceId) !== -1;
        }

        function isUrgent() {
            return false;
        }

        function toplevelCount() {
            return 0;
        }

        function switchTo(workspaceId) {
            switchedTo = switchedTo.concat([workspaceId]);
        }
    }

    Component {
        id: workspaces

        Bar.Workspaces {
            appearance: profile
            monitorScreen: "screen"
            monitors: ({ workspacesFor: () => 4 })
            workspaceService: fakeService
        }
    }

    function init() {
        fakeService.shownOnMonitor = 2;
        fakeService.switchedTo = [];
        profile.barElements = BarProfileModel.normalizeBarElements({
            left: [{ id: "workspaces", enabled: true, options: { hideEmpty: false } }],
            center: [], right: []
        });
    }

    function shown() {
        const element = createTemporaryObject(workspaces, this);
        waitForRendering(element);
        return element;
    }

    function test_scrollingGoesToTheNextOrPreviousWorkspace() {
        const element = shown();

        mouseWheel(element, 10, 10, 0, -120);
        compare(fakeService.switchedTo, [3]);
        mouseWheel(element, 10, 10, 0, 120);
        compare(fakeService.switchedTo, [3, 1]);
    }

    function test_scrollingPastEitherEndDoesNothing() {
        const element = shown();

        fakeService.shownOnMonitor = 4;
        mouseWheel(element, 10, 10, 0, -120);
        fakeService.shownOnMonitor = 1;
        mouseWheel(element, 10, 10, 0, 120);
        compare(fakeService.switchedTo, []);
    }

    // With empty workspaces hidden, scrolling skips them as the element does.
    function test_scrollingSkipsTheWorkspacesTheElementHides() {
        profile.barElements = BarProfileModel.normalizeBarElements({
            left: [{ id: "workspaces", enabled: true, options: { hideEmpty: true } }],
            center: [], right: []
        });
        const element = shown();

        mouseWheel(element, 10, 10, 0, -120);
        compare(fakeService.switchedTo, [4]);
    }
}
