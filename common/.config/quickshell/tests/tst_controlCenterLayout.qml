import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion

// The control center's two stages. Collapsed (the bell, SUPER+N) shows the
// tile row above the notifications; expanded (SUPER+C, the chevron, a drag
// down on the handle) shows every control in place of the notifications.
// With the control center plugin off it is notifications only.
// Pointer events don't reach items under qmltestrunner offscreen, so the
// handle is driven through what its tap and drag call.
TestCase {
    name: "ControlCenterLayout"
    width: 500
    height: 700
    visible: true
    when: windowShown

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    Component {
        id: fakeControls

        Rectangle {
            objectName: "controls"
            width: 400
            height: 80
        }
    }

    Component {
        id: fakeNotifications

        Rectangle {
            objectName: "notifications"
            width: 400
            height: 200
        }
    }

    Component {
        id: layoutComponent

        Panels.ControlCenterLayout {
            appearance: barAppearance
            width: 400
            controls: fakeControls
            notifications: fakeNotifications
        }
    }

    function makeLayout(properties) {
        const layout = createTemporaryObject(layoutComponent, this, properties || {});
        verify(layout);
        return layout;
    }

    function opened(layout, stage) {
        layout.requestedStage = stage;
        layout.open = true;
    }

    function closed(layout) {
        layout.open = false;
    }

    function controlsShown(layout) {
        const controls = findChild(layout, "controls");
        return controls !== null && controls.visible;
    }

    function notificationsShown(layout) {
        const list = findChild(layout, "notifications");
        verify(list);
        return list.visible;
    }

    function test_theBellOpensItCollapsedWithTheTileRowAboveTheNotifications() {
        const layout = makeLayout();
        opened(layout, "collapsed");

        compare(layout.expanded, false);
        verify(controlsShown(layout));
        verify(notificationsShown(layout));
    }

    function test_superCOpensItExpandedInPlaceOfTheNotifications() {
        const layout = makeLayout();
        opened(layout, "expanded");

        compare(layout.expanded, true);
        verify(controlsShown(layout));
        verify(!notificationsShown(layout));
    }

    function test_eachOpeningChoosesItsOwnStage() {
        const layout = makeLayout();
        opened(layout, "expanded");
        layout.toggleStage();
        closed(layout);

        opened(layout, "expanded");
        compare(layout.expanded, true);
        closed(layout);

        opened(layout, "collapsed");
        compare(layout.expanded, false);
    }

    function test_theChevronSwitchesStagesAndCollapsingBringsTheListBack() {
        const layout = makeLayout();
        opened(layout, "collapsed");

        layout.toggleStage();
        compare(layout.expanded, true);
        verify(!notificationsShown(layout));

        layout.toggleStage();
        compare(layout.expanded, false);
        verify(notificationsShown(layout));
    }

    function test_draggingTheHandleDownExpandsAndUpCollapses() {
        const layout = makeLayout();
        opened(layout, "collapsed");

        layout.dragged(60);
        compare(layout.expanded, true);
        layout.dragged(60);
        compare(layout.expanded, true);

        layout.dragged(-60);
        compare(layout.expanded, false);
        layout.dragged(-60);
        compare(layout.expanded, false);
    }

    function test_aShortDragKeepsTheStage() {
        const layout = makeLayout();
        opened(layout, "collapsed");

        layout.dragged(8);
        compare(layout.expanded, false);
    }

    function test_withThePluginOffItIsNotificationsOnly() {
        const layout = makeLayout({ controlsEnabled: false });
        opened(layout, "expanded");

        compare(layout.expanded, false);
        verify(!controlsShown(layout));
        verify(notificationsShown(layout));
        compare(findChild(layout, "stageHandle").visible, false);

        layout.toggleStage();
        layout.dragged(60);
        compare(layout.expanded, false);
        verify(notificationsShown(layout));
    }

    function test_turningThePluginOffWhileExpandedBringsTheListBack() {
        const layout = makeLayout();
        opened(layout, "expanded");

        layout.controlsEnabled = false;
        compare(layout.expanded, false);
        verify(!controlsShown(layout));
        verify(notificationsShown(layout));
    }
}
