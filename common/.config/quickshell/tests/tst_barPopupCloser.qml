import QtQuick
import QtTest
import "../components/bar" as Bar

// Pressing a bar element that opens no popup closes the open one, before the
// element's own click runs. Bar elements with a popup and empty bar space
// leave it alone.
TestCase {
    name: "BarPopupCloser"
    width: 400
    height: 100
    when: windowShown
    // Shown, so that clicks reach the bar.
    visible: true

    // A bar of stand-in elements, each answering clicks the way the real one
    // does. Cava sits inside another item, as BarElementItems' elements do.
    Component {
        id: barWithElements

        Item {
            id: fakeBar

            property alias workspaces: workspaces
            property alias settingsButton: settingsButton
            property alias battery: battery
            property alias cava: cava
            // What the bar did, in order.
            property var events: []

            function record(event) {
                events = events.concat(event);
            }

            width: 400
            height: 40

            Rectangle {
                id: workspaces

                width: 50
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: settingsButton

                x: 60
                width: 50
                height: parent.height

                TapHandler {
                    onTapped: fakeBar.record("settings opened")
                }
            }

            Rectangle {
                id: battery

                x: 120
                width: 50
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                    onClicked: fakeBar.record("battery toggled")
                }
            }

            Item {
                x: 180
                width: 200
                height: parent.height

                Rectangle {
                    id: cava

                    x: 10
                    width: 50
                    height: parent.height
                }
            }

            Bar.BarPopupCloser {
                elementItems: ({
                    "workspaces": workspaces,
                    "arch": settingsButton,
                    "battery": battery,
                    "cava": cava
                })
                onCloseRequested: fakeBar.record("popup closed")
            }
        }
    }

    function makeBar() {
        return createTemporaryObject(barWithElements, this);
    }

    function test_clickingAWorkspaceClosesThePopup() {
        const bar = makeBar();

        mouseClick(bar.workspaces);
        compare(bar.events, ["popup closed"]);
    }

    function test_clickingABarElementThatDoesNothingClosesThePopup() {
        const bar = makeBar();

        mouseClick(bar.cava);
        compare(bar.events, ["popup closed"]);
    }

    function test_everyClickOnSuchABarElementClosesThePopup() {
        const bar = makeBar();

        mouseClick(bar.workspaces);
        mouseClick(bar.workspaces);
        compare(bar.events, ["popup closed", "popup closed"]);
    }

    // The settings panel can't take the keyboard while the popup's focus grab holds.
    function test_thePopupClosesBeforeTheSettingsButtonOpensThePanel() {
        const bar = makeBar();

        mouseClick(bar.settingsButton);
        compare(bar.events, ["popup closed", "settings opened"]);
    }

    function test_pressingIsEnoughToCloseThePopup() {
        const bar = makeBar();

        mousePress(bar.workspaces);
        compare(bar.events, ["popup closed"]);
        mouseRelease(bar.workspaces);
    }

    function test_aBarElementWithAPopupKeepsTogglingItItself() {
        const bar = makeBar();

        mouseClick(bar.battery);
        compare(bar.events, ["battery toggled"]);
    }

    function test_clickingEmptyBarSpaceLeavesThePopupOpen() {
        const bar = makeBar();

        mouseClick(bar, 115, 20);
        compare(bar.events, []);
    }

    function test_aHiddenBarElementTakesNoClick() {
        const bar = makeBar();

        bar.cava.visible = false;
        mouseClick(bar, bar.cava.mapToItem(bar, 25, 20).x, 20);
        compare(bar.events, []);
    }

    function test_anyMouseButtonClosesThePopup() {
        const bar = makeBar();

        mouseClick(bar.workspaces, 25, 20, Qt.RightButton);
        compare(bar.events, ["popup closed"]);
    }
}
