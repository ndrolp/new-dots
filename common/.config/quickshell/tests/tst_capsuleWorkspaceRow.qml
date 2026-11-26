import QtQuick
import QtTest
import "../components/bar"
import "../config" as Config

// The capsule's workspace pills at rest: one small pill per workspace of its
// monitor with windows, and the active one even when empty, with no label; the
// active one wider and in the accent, an urgent one red and an occupied one
// dim; an empty one has no pill. A click on a pill switches to its workspace;
// scrolling goes through every workspace, empty ones too.
TestCase {
    name: "CapsuleWorkspaceRow"
    width: 300
    height: 100
    visible: true
    when: windowShown

    // Hyprland's workspaces as the workspace service shows them.
    QtObject {
        id: workspaces

        property int focused: 2
        property var occupied: [1, 3]
        property var urgent: []
        property var switchedTo: []
        // The workspace the row's monitor shows, which need not be focused.
        property int shownOnMonitor: 2

        function activeWorkspaceIdForScreen(screen) {
            return screen === "monitor" ? shownOnMonitor : -1;
        }

        function isActive(id) {
            return id === focused;
        }

        function isOccupied(id) {
            return occupied.indexOf(id) !== -1;
        }

        function isUrgent(id) {
            return urgent.indexOf(id) !== -1;
        }

        function switchTo(id) {
            switchedTo = switchedTo.concat([id]);
        }
    }

    Component {
        id: area

        Rectangle {
            property alias row: row

            width: 300
            height: 100
            color: "#ffffff"

            CapsuleWorkspaceRow {
                id: row

                x: 10
                y: 10
                workspaceIds: [1, 2, 3]
                workspaceService: workspaces
                monitorScreen: "monitor"
                occupiedColor: "#ff0000"
                urgentColor: "#ffff00"
                activeColor: "#00ff00"
                appearance: ({
                    spacing: 4,
                    motion: { brief: 0, short: 0, medium: 0, long: 0, easing: 0 }
                })
            }
        }
    }

    Config.Theme {
        id: theme
    }

    Component {
        id: plainRow

        CapsuleWorkspaceRow {
            workspaceIds: [1, 2, 3]
            workspaceService: workspaces
            monitorScreen: "monitor"
            appearance: ({
                spacing: 4,
                motion: { brief: 0, short: 0, medium: 0, long: 0, easing: 0 }
            })
        }
    }

    function init() {
        workspaces.focused = 2;
        workspaces.occupied = [1, 3];
        workspaces.urgent = [];
        workspaces.switchedTo = [];
        workspaces.shownOnMonitor = 2;
    }

    // The pill shown for a workspace.
    function pillFor(row, id) {
        return row.pills.find(pill => pill.workspaceId === id);
    }

    function colorAt(item, x, y) {
        const pixel = grabImage(item).pixel(x, y);
        return { r: Math.round(pixel.r), g: Math.round(pixel.g), b: Math.round(pixel.b) };
    }

    // Pills 4 deep and 8 long, the active one twice as long, the profile's
    // spacing apart.
    function test_thereIsOneSmallPillPerWorkspaceInOrder() {
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.pills.map(pill => [pill.x, pill.width, pill.height, pill.radius]),
            [[0, 8, 4, 2], [12, 16, 4, 2], [32, 8, 4, 2]]);
        compare(built.row.implicitWidth, 40);
        compare(built.row.implicitHeight, 4);
    }

    function test_thePillsHaveNoLabel() {
        const built = createTemporaryObject(area, this);

        for (const pill of built.row.pills)
            compare(pill.children.filter(child => child.text !== undefined).length, 0);
    }

    function test_theActiveWorkspaceIsHighlightedAndFollowsChanges() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 20, 10 + 2), { r: 0, g: 1, b: 0 });
        workspaces.focused = 3;
        tryCompare(pillFor(built.row, 3), "active", true);
        compare(built.row.pills.map(pill => pill.workspaceId), [1, 3]);
    }

    function test_anEmptyWorkspaceHasNoPill() {
        workspaces.occupied = [1];
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2]);
        compare(built.row.implicitWidth, 28);
        workspaces.occupied = [1, 3];
        tryCompare(built.row, "implicitWidth", 40);
        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
    }

    function test_theActiveWorkspaceHasAPillEvenWhenEmpty() {
        workspaces.occupied = [];
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [2]);
        workspaces.focused = 3;
        tryCompare(built.row, "pills", [pillFor(built.row, 3)]);
        compare(colorAt(built, 10 + 8, 10 + 2), { r: 0, g: 1, b: 0 });
    }

    // One asking for attention is red until it is active.
    function test_occupiedAndUrgentWorkspacesLookDifferent() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 4, 10 + 2), { r: 1, g: 0, b: 0 });
        workspaces.urgent = [3];
        tryCompare(pillFor(built.row, 3), "urgent", true);
        compare(colorAt(built, 10 + 36, 10 + 2), { r: 1, g: 1, b: 0 });
        workspaces.focused = 3;
        tryCompare(pillFor(built.row, 3), "urgent", false);
        // Workspace 2, empty and no longer active, has gone.
        compare(colorAt(built, 10 + 20, 10 + 2), { r: 0, g: 1, b: 0 });
    }

    // Unless told otherwise, an occupied pill is the text at about 40%,
    // quieter than the active and urgent ones.
    function test_anOccupiedPillIsDimText() {
        const row = createTemporaryObject(plainRow, this);

        compare(row.occupiedColor.a.toFixed(2), "0.40");
        compare([row.occupiedColor.r, row.occupiedColor.g, row.occupiedColor.b],
            [theme.text.r, theme.text.g, theme.text.b]);
    }

    // The pills are small, so each takes clicks a little past its edges.
    function test_clickingAPillSwitchesToItsWorkspace() {
        const built = createTemporaryObject(area, this);

        mouseClick(built.row.pills[2]);
        compare(workspaces.switchedTo, [3]);
        mouseClick(built.row.pills[0], 4, -1);
        compare(workspaces.switchedTo, [3, 1]);
    }

    // Down goes to the next workspace the monitor shows, up to the previous
    // one, from the one it shows even while another monitor has focus.
    function test_scrollingOverThePillsGoesToTheNextOrPreviousWorkspace() {
        const built = createTemporaryObject(area, this);

        workspaces.focused = 7;
        mouseWheel(built.row, 20, 2, 0, -120);
        compare(workspaces.switchedTo, [3]);
        mouseWheel(built.row, 20, 2, 0, 120);
        compare(workspaces.switchedTo, [3, 1]);
    }

    // Scrolling steps through every workspace the monitor shows, even an
    // empty one with no pill.
    function test_scrollingReachesAnEmptyWorkspace() {
        workspaces.focused = 1;
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 3]);
        workspaces.shownOnMonitor = 1;
        mouseWheel(built.row, 4, 2, 0, -120);
        workspaces.shownOnMonitor = 3;
        mouseWheel(built.row, 4, 2, 0, 120);
        compare(workspaces.switchedTo, [2, 2]);
    }

    function test_scrollingPastEitherEndDoesNothing() {
        const built = createTemporaryObject(area, this);

        workspaces.shownOnMonitor = 3;
        mouseWheel(built.row, 20, 2, 0, -120);
        workspaces.shownOnMonitor = 1;
        mouseWheel(built.row, 20, 2, 0, 120);
        compare(workspaces.switchedTo, []);
    }

    // The pills are small, so they take a scroll a little past their edges,
    // as they take clicks.
    function test_scrollingJustPastThePillsStillCounts() {
        const built = createTemporaryObject(area, this);

        mouseWheel(built.row, 20, -1, 0, -120);
        compare(workspaces.switchedTo, [3]);
    }
}
