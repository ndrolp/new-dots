import QtQuick
import QtTest
import "../components/bar"
import "../config" as Config

// The capsule's workspace pills. At rest: one small pill per workspace of its
// monitor, with no label; the shown one wider and in the accent, an urgent
// one red, an occupied one dim and an empty one dimmer. Expanded: every workspace is a chip with
// its number or glyph, in the same colours, an empty one dim and clickable;
// collapsed, they are pills again. A click on a pill switches to its
// workspace; scrolling goes through every workspace, empty ones too.
TestCase {
    name: "CapsuleWorkspaceRow"
    width: 300
    height: 100
    visible: true
    when: windowShown

    // Hyprland's workspaces as the workspace service shows them.
    QtObject {
        id: workspaces

        // The workspace with focus, which can be on another monitor.
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

    // Instant, as with reduce motion.
    readonly property var instant: ({
        brief: 0, short: 0, medium: 0, long: 0, easing: 0,
        capsule: {
            expand: { duration: 0, easing: 34, overshoot: 0.9 },
            collapse: { duration: 0, easing: 6, overshoot: 0 }
        }
    })

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
                emptyColor: "#0000ff"
                appearance: ({ spacing: 4, textSize: 14, motion: instant })
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
            appearance: ({ spacing: 4, textSize: 14, motion: instant })
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

    // Pills 4 deep and 8 long, the shown one twice as long, the profile's
    // spacing apart.
    function test_thereIsOneSmallPillPerWorkspaceInOrder() {
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.pills.map(pill => [pill.x, pill.width, pill.height, pill.radius]),
            [[0, 8, 4, 2], [12, 16, 4, 2], [32, 8, 4, 2]]);
        compare(built.row.implicitWidth, 40);
        compare(built.row.height, 4);
        compare(built.row.length, 40);
        compare(built.row.depth, 4);
    }

    // The bar hides the row until the capsule has its place, a place that
    // takes the row's length: the length must not hang on the row being
    // shown, or the two would wait on each other in a binding loop.
    function test_aHiddenRowKeepsItsPillsAndLength() {
        const built = createTemporaryObject(area, this);

        built.row.visible = false;
        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.length, 40);
    }

    function test_atRestThePillsHaveNoLabel() {
        const built = createTemporaryObject(area, this);

        for (const pill of built.row.pills)
            compare(pill.label.visible, false);
    }

    function test_theShownWorkspaceIsHighlightedAndFollowsChanges() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 20, 10 + 2), { r: 0, g: 1, b: 0 });
        workspaces.shownOnMonitor = 3;
        tryCompare(pillFor(built.row, 3), "role", "shown");
        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
    }

    // On a monitor without focus, the workspace it shows keeps its long
    // accent pill, even when empty.
    function test_anUnfocusedMonitorKeepsItsShownPill() {
        workspaces.occupied = [];
        workspaces.focused = 7;
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => [pill.workspaceId, pill.width]), [[1, 8], [2, 16], [3, 8]]);
        compare(colorAt(built, 10 + 20, 10 + 2), { r: 0, g: 1, b: 0 });
    }

    // Every workspace of the monitor has a pill at rest, an empty one too, in
    // the empty colour.
    function test_atRestEveryWorkspaceHasAPill() {
        workspaces.occupied = [1];
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.implicitWidth, 40);
        compare(colorAt(built, 10 + 36, 10 + 2), { r: 0, g: 0, b: 1 });
    }

    // One asking for attention is red until it is shown.
    function test_occupiedAndUrgentWorkspacesLookDifferent() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 4, 10 + 2), { r: 1, g: 0, b: 0 });
        workspaces.urgent = [3];
        tryCompare(pillFor(built.row, 3), "role", "urgent");
        compare(colorAt(built, 10 + 36, 10 + 2), { r: 1, g: 1, b: 0 });
        workspaces.shownOnMonitor = 3;
        tryCompare(pillFor(built.row, 3), "role", "shown");
        // Workspace 2, empty and no longer shown, is in the empty colour.
        compare(colorAt(built, 10 + 16, 10 + 2), { r: 0, g: 0, b: 1 });
        compare(colorAt(built, 10 + 32, 10 + 2), { r: 0, g: 1, b: 0 });
    }

    // Unless told otherwise, an occupied pill is the text at about 40%,
    // quieter than the shown and urgent ones, and an empty chip quieter
    // still.
    function test_occupiedAndEmptyPillsAreDimText() {
        const row = createTemporaryObject(plainRow, this);

        compare(row.occupiedColor.a.toFixed(2), "0.40");
        compare([row.occupiedColor.r, row.occupiedColor.g, row.occupiedColor.b],
            [theme.text.r, theme.text.g, theme.text.b]);
        verify(row.emptyColor.a < row.occupiedColor.a);
        compare([row.emptyColor.r, row.emptyColor.g, row.emptyColor.b],
            [theme.text.r, theme.text.g, theme.text.b]);
    }

    // Expanded, every workspace is a chip with its number, as deep as the
    // chips (the text size and 2) and its label plus half that on either
    // side, the shown one half a chip longer on either side.
    function test_expandedEveryWorkspaceIsANumberedChip() {
        workspaces.occupied = [1];
        const built = createTemporaryObject(area, this);

        built.row.expanded = true;
        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.pills.map(pill => pill.label.text), ["1", "2", "3"]);
        for (const pill of built.row.pills) {
            compare(pill.label.visible, true);
            compare(pill.height, 16);
            compare(pill.width, pill.label.implicitWidth + (pill.role === "shown" ? 32 : 16));
        }
        compare(built.row.depth, 16);
        compare(built.row.height, 16);
        compare(built.row.length, built.row.pills.reduce((total, pill) => total + pill.width, 8));
    }

    // With glyphs on the workspaces bar element, a chip shows its glyph.
    function test_expandedAChipShowsItsGlyph() {
        const built = createTemporaryObject(area, this);

        built.row.workspaceOptions = { glyphsEnabled: true, glyphs: ["a", "", "c"] };
        built.row.expanded = true;
        compare(built.row.pills.map(pill => pill.label.text), ["a", "2", "c"]);
    }

    // Empty workspaces come back as dim chips, which switch to theirs on a
    // click.
    function test_expandedAnEmptyWorkspaceIsADimClickableChip() {
        workspaces.occupied = [1];
        workspaces.shownOnMonitor = 1;
        const built = createTemporaryObject(area, this);

        built.row.expanded = true;
        waitForItemPolished(built.row);
        const empty = pillFor(built.row, 3);
        compare(empty.role, "empty");
        compare(colorAt(built, 10 + empty.x + 3, 10 + empty.height / 2), { r: 0, g: 0, b: 1 });
        mouseClick(empty);
        compare(workspaces.switchedTo, [3]);
    }

    // Collapsing returns to the pills at rest, with no label.
    function test_collapsingReturnsToThePills() {
        const built = createTemporaryObject(area, this);

        built.row.expanded = true;
        built.row.expanded = false;
        compare(built.row.pills.map(pill => [pill.workspaceId, pill.width, pill.height, pill.label.visible]),
            [[1, 8, 4, false], [2, 16, 4, false], [3, 8, 4, false]]);
        compare(built.row.depth, 4);
        compare(built.row.length, 40);
    }

    // With motion, chips grow on the capsule's spring; the row's depth and
    // length, which size the capsule, are where they are headed at once.
    function test_withMotionTheChipsGrowOnTheSpring() {
        const built = createTemporaryObject(area, this);
        built.row.appearance = {
            spacing: 4, textSize: 14,
            motion: {
                brief: 100, short: 100, medium: 100, long: 100, easing: 6,
                capsule: {
                    expand: { duration: 300, easing: 34, overshoot: 0.9 },
                    collapse: { duration: 300, easing: 6, overshoot: 0 }
                }
            }
        };

        built.row.expanded = true;
        compare(built.row.depth, 16);
        verify(pillFor(built.row, 1).height < 16);
        tryCompare(pillFor(built.row, 1), "height", 16);
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

    // Scrolling steps through every workspace the monitor shows, an empty
    // one too.
    function test_scrollingReachesAnEmptyWorkspace() {
        workspaces.shownOnMonitor = 1;
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
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
