import QtQuick
import QtTest
import "../components/bar" as Bar
import "../config/BarProfileModel.js" as BarProfileModel

// On a side bar workspaces, icon and value elements stack upright: what runs
// along a top or bottom bar runs down it, and they fill the same thickness
// across it.
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
        property bool barBorder: false
        property bool elementBorder: false
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

    Component {
        id: signalSpy

        SignalSpy {}
    }

    Component {
        id: elementText

        Bar.ElementText {
            appearance: profile
            font.pixelSize: 14
            font.bold: true
        }
    }

    Component {
        id: iconValue

        Bar.IconValue {
            appearance: profile
            icon: "󰁹"
            iconSize: 14
            valueSize: 12
            value: "87%"
        }
    }

    Component {
        id: recordingContent

        Bar.RecordingContent {
            appearance: profile
            maximumLength: 120
            elapsed: "1:02:03"
        }
    }

    Component {
        id: audioLevel

        Bar.AudioLevel {
            appearance: profile
            volume: 0.5
            muted: false
        }
    }

    Component {
        id: monitor

        Bar.SystemMonitor {
            appearance: profile
            systemMonitor: ({ cpuUsage: 100, memoryUsage: 100, temperature: 87 })
        }
    }

    function init() {
        profile.barPosition = "left";
        profile.barTransparent = false;
        profile.barHeight = 40;
        profile.elementVerticalPadding = 3;
        fakeService.activeWorkspace = 2;
    }

    // The default profile's thickness: a 32px bar with 5px around its elements.
    function useDefaultThickness() {
        profile.barHeight = 32;
        profile.elementVerticalPadding = 5;
    }

    function verifyReadable(text) {
        verify(text.paintedWidth <= 22, text.text + " runs " + text.paintedWidth + "px across a 22px element");
        verify(text.fontInfo.pixelSize >= 9, text.text + " shrank to " + text.fontInfo.pixelSize + "px");
    }

    // What a stack shows, in order.
    function drawn(stack) {
        const found = [];
        for (let index = 0; index < stack.children.length; index++) {
            if (stack.children[index].visible && stack.children[index].width > 0)
                found.push(stack.children[index]);
        }
        return found;
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

    function test_aValueStandsUprightOnASideBar() {
        const text = shown(elementText, { value: "12:34" });

        compare(text.text, "12\n34");
    }

    function test_aValueStaysAsItIsOnATopBar() {
        profile.barPosition = "top";

        const text = shown(elementText, { value: "87%" });

        compare(text.text, "87%");
        compare(text.width, text.implicitWidth);
    }

    function test_aFullValueFitsAcrossTheDefaultThickness() {
        useDefaultThickness();

        verifyReadable(shown(elementText, { value: "100%" }));
    }

    function test_aShortValueKeepsItsSize() {
        useDefaultThickness();

        compare(shown(elementText, { value: "12:34" }).fontInfo.pixelSize, 14);
    }

    function test_aStackedValueReportsTheLinesItTakes() {
        const single = shown(elementText, { value: "12" });
        const stacked = shown(elementText, { value: "12:34" });

        verify(stacked.implicitHeight >= single.implicitHeight * 2 - 1,
            single.implicitHeight + " high becomes " + stacked.implicitHeight);
    }

    function test_theValueGoesUnderTheIconOnASideBar() {
        const stack = shown(iconValue);
        const [icon, slot] = drawn(stack);

        compare(slot.y, icon.height);
        compare(stack.implicitHeight, icon.height + slot.height);
        compare(icon.x + icon.width / 2, stack.implicitWidth / 2);
        compare(slot.x + slot.width / 2, stack.implicitWidth / 2);
    }

    function test_theValueSitsBesideTheIconOnATopBar() {
        profile.barPosition = "top";

        const stack = shown(iconValue);
        const [icon, slot] = drawn(stack);

        compare(slot.x, icon.width + stack.spacing);
        compare(stack.implicitHeight, icon.height);
        compare(stack.implicitWidth, icon.width + stack.spacing + slot.width);
    }

    function test_aSmallerValueLandsOnAWholePixelBesideTheIcon() {
        profile.barPosition = "top";

        for (let valueSize = 8; valueSize <= 14; valueSize++) {
            const [, slot] = drawn(shown(iconValue, { iconSize: 14, valueSize: valueSize }));
            const value = drawn(slot)[0];

            compare(value.y, Math.round(value.y), "at " + valueSize + "px");
        }
    }

    function test_aHiddenValueLeavesTheIconAlone() {
        const stack = shown(iconValue, { valueVisible: false });

        compare(stack.implicitHeight, drawn(stack)[0].height);
    }

    readonly property string manyApps: "Firefox, Discord, OBS Studio, Google Chrome, Slack, Zoom Workplace"

    function test_theRecordingTimeStandsUprightOnASideBar() {
        const [value] = drawn(shown(recordingContent));
        const [, slot] = drawn(value);

        compare(slot.children[0].text, "1\n02\n03");
    }

    function test_theAppsSharingRunSidewaysOnASideBar() {
        const element = shown(recordingContent, { sharing: "Firefox, Discord" });
        const [row] = drawn(element);
        const [icon, text] = drawn(row);

        compare(row.rotation, 90);
        compare(icon.rotation, -90);
        compare(text.text, "Firefox, Discord");
        compare(text.lineCount, 1);
        compare(element.implicitHeight, row.implicitWidth);
        compare(element.implicitWidth, row.implicitHeight);
    }

    function test_longAppsSharingEndInAnEllipsisOnASideBar() {
        const element = shown(recordingContent, { sharing: manyApps });
        const [row] = drawn(element);
        const [, text] = drawn(row);

        compare(text.width, 120);
        compare(text.elide, Text.ElideRight);
        verify(text.truncated, "the text is cut");
    }

    function test_theAppsSharingStayInLineOnATopBar() {
        profile.barPosition = "top";

        const element = shown(recordingContent, { sharing: manyApps });
        const [value] = drawn(element);
        const [, slot] = drawn(value);

        compare(slot.children[0].text, manyApps);
        verify(element.implicitWidth > 120, "nothing caps it");
        compare(element.implicitWidth, value.implicitWidth);
    }

    function test_theVolumeMeterGoesUnderTheIconOnASideBar() {
        const [icon, meter] = drawn(shown(audioLevel));

        verify(meter.y >= icon.height);
        verify(meter.width <= 28, "the meter runs " + meter.width + "px across a 34px element");
    }

    function test_theVolumeMeterFitsAcrossTheDefaultThickness() {
        useDefaultThickness();

        verify(shown(audioLevel).implicitWidth <= 22);
    }

    function test_theVolumeMeterStaysBesideTheIconOnATopBar() {
        profile.barPosition = "top";

        const level = shown(audioLevel);
        const [icon, meter] = drawn(level);

        compare(meter.x, icon.width + 7);
        compare(meter.width, 34);
        compare(level.implicitHeight, icon.height);
    }

    function test_theMeterIsCentredBesideTheIconOnThePixel() {
        profile.barPosition = "top";

        const [, slot] = drawn(shown(audioLevel));
        const bar = slot.children[0];

        compare(bar.height, 4);
        compare(bar.y, Math.round(bar.y));
    }

    function test_thePercentageGoesUnderTheIconOnASideBar() {
        useDefaultThickness();

        const level = shown(audioLevel, { meterVisible: false, volume: 1 });
        const [icon, percentage] = drawn(level);

        compare(percentage.text, "100");
        verify(percentage.y >= icon.height);
        verifyReadable(percentage);
    }

    function test_theSystemMonitorStandsAcrossADefaultSideBar() {
        useDefaultThickness();

        const element = shown(monitor);

        compare(element.width, 22);
        verify(element.height > 3 * 2 * 12, "it is " + element.height + "px long");
    }

    function test_eachSystemMonitorValueIsReadable() {
        useDefaultThickness();

        const texts = drawn(shown(monitor).children[0]);

        compare(texts.length, 3);
        for (let index = 0; index < texts.length; index++) {
            compare(texts[index].lineCount, 2);
            verifyReadable(texts[index]);
        }
    }

    function test_theSystemMonitorStaysAsItWasOnATopBar() {
        profile.barPosition = "top";

        const element = shown(monitor);
        const metrics = element.children[0];
        const [first, second] = drawn(metrics);

        compare(element.height, 34);
        compare(element.width, metrics.implicitWidth + 16);
        compare(second.y, 0);
        compare(second.x, first.width + 8);
    }

    function test_theSystemMonitorStillOpensFromItsStack() {
        const element = shown(monitor);
        const clicks = createTemporaryObject(signalSpy, this, { target: element, signalName: "clicked" });

        mouseClick(element, element.width / 2, element.height - 4);

        compare(clicks.count, 1);
    }
}
