import QtQuick
import QtTest
import "../components/bar"

// The capsule's workspace row: one pill per workspace of its monitor, in the
// profile's background and border, the active one highlighted; a click on a
// pill switches to its workspace.
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
                fillColor: "#ff0000"
                borderColor: "#0000ff"
                activeColor: "#00ff00"
                appearance: ({
                    barPosition: "top",
                    workspaceButtonSize: 20,
                    pillVerticalPadding: 3,
                    activeWorkspaceHorizontalPadding: 5,
                    spacing: 4,
                    textSize: 1,
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

    // Pills 26 deep: 20 square, the active one 10 wider, 4 apart.
    function test_thereIsOnePillPerWorkspaceInOrder() {
        const built = createTemporaryObject(area, this);

        compare(built.row.pills.map(pill => pill.workspaceId), [1, 2, 3]);
        compare(built.row.pills.map(pill => [pill.x, pill.width, pill.height]),
            [[0, 26, 26], [30, 36, 26], [70, 26, 26]]);
        compare(built.row.implicitWidth, 96);
        compare(built.row.implicitHeight, 26);
    }

    function test_thePillsAreFilledWithTheProfilesBackground() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 13, 10 + 2), { r: 1, g: 0, b: 0 });
    }

    function test_theActiveWorkspaceIsHighlightedAndFollowsChanges() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 48, 10 + 2), { r: 0, g: 1, b: 0 });
        workspaces.focused = 3;
        tryCompare(built.row.pills[2], "active", true);
        compare(built.row.pills[1].active, false);
        compare(colorAt(built, 10 + 48, 10 + 2), { r: 1, g: 0, b: 0 });
    }

    function test_theBarBorderRunsAroundEachPillWhenOn() {
        const built = createTemporaryObject(area, this);

        compare(colorAt(built, 10 + 13, 10), { r: 1, g: 0, b: 0 });
        built.row.border = true;
        compare(colorAt(built, 10 + 13, 10), { r: 0, g: 0, b: 1 });
    }

    function test_clickingAPillSwitchesToItsWorkspace() {
        const built = createTemporaryObject(area, this);

        mouseClick(built.row.pills[2]);
        compare(workspaces.switchedTo, [3]);
    }
}
