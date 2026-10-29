import QtQuick
import QtTest
import "../components/bar" as Bar
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// The keep-awake bar element, always shown with a cup that is filled while
// keep-awake is on, and the popup it opens with keep-awake's on/off switch.
// Pointer events don't reach items under qmltestrunner offscreen, so the
// switch is toggled through its signal.
TestCase {
    name: "KeepAwake"
    width: 400
    height: 400
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        property bool pillsTransparent: false
        property bool transparentBarSlanted: false
        property bool barTransparentBorder: false
        readonly property var motion: Motion.motion(true)
    }

    // Stands in for services/KeepAwake.qml.
    Component {
        id: fakeKeepAwake

        QtObject {
            property bool on: false

            function toggle() {
                on = !on;
            }
        }
    }

    Component {
        id: element

        Bar.KeepAwakeElement {
            appearance: barAppearance
            height: 30
        }
    }

    Component {
        id: popupBody

        Panels.KeepAwakePopupBody {
            appearance: barAppearance
            width: 300
        }
    }

    function keepAwake(on) {
        return createTemporaryObject(fakeKeepAwake, this, { on: on });
    }

    function makeElement(on) {
        return createTemporaryObject(element, this, { keepAwake: keepAwake(on) });
    }

    function test_whileOffTheElementShowsAnOutlineCupInTheSubtextColor() {
        const item = makeElement(false);

        compare(item.icon.text, "󰛊");
        compare(item.icon.color, theme.textMuted);
    }

    function test_whileOnTheElementShowsAFilledCupInGreen() {
        const item = makeElement(true);

        compare(item.icon.text, "󰅶");
        compare(item.icon.color, theme.green);
    }

    function test_turningKeepAwakeOnOrOffDoesNotChangeTheElementsWidth() {
        const item = makeElement(false);
        const offWidth = item.width;

        item.keepAwake.on = true;

        verify(offWidth > 16);
        compare(item.width, offWidth);
    }

    // The popup's on/off switch.
    function switchOf(item) {
        if (item.checked !== undefined && item.toggled !== undefined)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = switchOf(item.children[i]);
            if (found)
                return found;
        }
        return null;
    }

    function makePopupBody(on) {
        return createTemporaryObject(popupBody, this, { keepAwake: keepAwake(on) });
    }

    function test_thePopupsSwitchTurnsKeepAwakeOnAndOff() {
        const item = makePopupBody(false);
        const popupSwitch = switchOf(item);

        popupSwitch.toggled();
        compare(item.keepAwake.on, true);

        popupSwitch.toggled();
        compare(item.keepAwake.on, false);
    }

    // The control center tile drives the same keep-awake, so the popup
    // follows a change made there.
    function test_thePopupsSwitchFollowsKeepAwakeTurnedOnElsewhere() {
        const item = makePopupBody(false);

        item.keepAwake.toggle();

        compare(switchOf(item).checked, true);
    }
}
