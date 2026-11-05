import QtQuick
import QtTest
import "../components/bar" as Bar
import "../config/BarProfileModel.js" as BarProfileModel

// On a side bar workspaces and icon elements stack upright: what runs along a
// top or bottom bar runs down it, and they fill the same thickness across it.
TestCase {
    name: "SideBarElements"
    width: 400
    height: 400
    // A positioner only lays out again what is shown, as in the bar.
    visible: true
    when: windowShown

    QtObject {
        id: profile

        property string barPosition: "left"
        property int barHeight: 40
        property int spacing: 4
        property int radius: 8
        property int workspaceButtonSize: 20
        property int textSize: 13
        property int archButtonHorizontalPadding: 5
        property int activeWorkspaceHorizontalPadding: 6
        property int pillVerticalPadding: 3
        property int elementVerticalPadding: 3
        property bool pillsTransparent: false
        property bool transparentBarSlanted: false
        property bool barTransparent: false
        property bool barTransparentBorder: false
        property var barElements: BarProfileModel.normalizeBarElements({
            left: [{ id: "workspaces", enabled: true }], center: [], right: []
        })
        property var motion: ({ short: 0, medium: 0, long: 0, brief: 0, easing: 0 })
    }

    QtObject {
        id: fakeService

        property int activeWorkspace: 2

        function workspacesForScreen() {
            return [1, 2, 3];
        }

        function monitorDescriptionForScreen() {
            return "monitor";
        }

        function isActive(workspaceId) {
            return workspaceId === activeWorkspace;
        }

        function isOccupied() {
            return false;
        }

        function isUrgent() {
            return false;
        }

        function toplevelCount() {
            return 0;
        }
    }

    Component {
        id: workspaces

        Bar.Workspaces {
            appearance: profile
            monitorScreen: null
            monitors: ({ workspacesFor: () => 3 })
            workspaceService: fakeService
        }
    }

    Component {
        id: archButton

        Bar.ArchButton {
            appearance: profile
        }
    }

    Component {
        id: keepAwakeElement

        Bar.KeepAwakeElement {
            appearance: profile
            keepAwake: ({ on: false })
        }
    }

    function init() {
        profile.barPosition = "left";
        profile.barTransparent = false;
        fakeService.activeWorkspace = 2;
    }

    // The workspace buttons of a Workspaces element, in workspace order.
    function buttons(element) {
        const stack = element.children[0];
        const found = [];
        for (let index = 0; index < stack.children.length; index++) {
            if (stack.children[index].workspaceId)
                found.push(stack.children[index]);
        }
        return found;
    }

    function shown(component, properties) {
        const element = createTemporaryObject(component, this, properties || {});
        waitForRendering(element);
        return element;
    }

    function test_workspacesStackDownASideBar_data() {
        return [{ tag: "left" }, { tag: "right" }];
    }

    function test_workspacesStackDownASideBar(data) {
        profile.barPosition = data.tag;

        const [first, second, third] = buttons(shown(workspaces));

        compare([first.x, first.y], [0, 0]);
        compare([second.x, second.y], [0, 24]);
        compare([third.x, third.y], [0, 60]);
    }

    function test_theActiveWorkspaceIsLongerAlongASideBar() {
        const [first, second] = buttons(shown(workspaces));

        compare([first.width, first.height], [34, 20]);
        compare([second.width, second.height], [34, 32]);
    }

    function test_workspacesRunAlongATopBar() {
        profile.barPosition = "top";

        const [first, second, third] = buttons(shown(workspaces));

        compare([first.x, first.y, first.width, first.height], [0, 0, 20, 34]);
        compare([second.x, second.y, second.width, second.height], [24, 0, 32, 34]);
        compare([third.x, third.y], [60, 0]);
    }

    function test_aWorkspacesElementWrapsItsStack() {
        const element = shown(workspaces);

        compare([element.width, element.height], [34, 80]);
    }

    function test_aFloatingWorkspacesElementKeepsItsPillAroundTheStack() {
        profile.barTransparent = true;

        const element = shown(workspaces);

        compare([element.width, element.height], [28, 96]);
    }

    function test_aGroupedWorkspacesElementLeavesThePillToItsGroup() {
        profile.barTransparent = true;

        const element = shown(workspaces, { grouped: true });

        compare([element.width, element.height], [18, 80]);
    }

    function test_theActiveWorkspaceMovesWithoutChangingTheStackLength() {
        const element = shown(workspaces);
        const [first, second, third] = buttons(element);

        fakeService.activeWorkspace = 3;
        fakeService.activeWorkspaceChanged();

        tryCompare(third, "height", 32);
        tryCompare(third, "y", 48);
        compare(element.height, 80);
    }

    function test_theArchButtonFillsAcrossASideBar() {
        const element = shown(archButton);

        compare([element.width, element.height], [34, 30]);
    }

    function test_theArchButtonStaysAsItWasOnATopBar() {
        profile.barPosition = "top";

        const element = shown(archButton);

        compare([element.width, element.height], [30, 34]);
    }

    function test_keepAwakeFillsAcrossASideBar() {
        const element = shown(keepAwakeElement);

        compare(element.width, 34);
        verify(element.height > 16, "its length is its cup and padding");
    }

    function test_keepAwakeStaysAsItWasOnATopBar() {
        profile.barPosition = "top";

        const element = shown(keepAwakeElement);

        compare(element.height, 34);
        verify(element.width > 16, "its length is its cup and padding");
    }
}
