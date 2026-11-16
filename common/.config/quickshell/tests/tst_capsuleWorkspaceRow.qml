import QtQuick
import QtTest
import "../components/bar"

// The capsule's workspace pills: one small pill per workspace of its monitor,
// with no label, the active one wider and highlighted; a click on a pill
// switches to its workspace.
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
        property var switchedTo: []

        function isActive(id) {
            return id === focused;
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
                idleColor: "#ff0000"
                activeColor: "#00ff00"
                appearance: ({
                    spacing: 4,
                    motion: { brief: 0, short: 0, medium: 0, long: 0, easing: 0 }
                })
            }
        }
    }

    function init() {
        workspaces.focused = 2;
        workspaces.switchedTo = [];
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

        compare(colorAt(built, 10 + 4, 10 + 2), { r: 1, g: 0, b: 0 });
        compare(colorAt(built, 10 + 20, 10 + 2), { r: 0, g: 1, b: 0 });
        workspaces.focused = 3;
        tryCompare(built.row.pills[2], "active", true);
        compare(built.row.pills[1].active, false);
    }

    // The pills are small, so each takes clicks a little past its edges.
    function test_clickingAPillSwitchesToItsWorkspace() {
        const built = createTemporaryObject(area, this);

        mouseClick(built.row.pills[2]);
        compare(workspaces.switchedTo, [3]);
        mouseClick(built.row.pills[0], 4, -1);
        compare(workspaces.switchedTo, [3, 1]);
    }
}
