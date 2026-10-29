import QtQuick
import QtTest
import "../components/bar" as Bar
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// The keep-awake bar element, always shown with a cup that is filled while
// keep-awake is on, and the popup it opens with keep-awake's on/off switch,
// its duration choice and the time left on a timed keep-awake.
// Pointer events don't reach items under qmltestrunner offscreen, so the
// switch and the duration buttons are pressed through their signals.
TestCase {
    name: "KeepAwake"
    width: 400
    height: 400
    // Shown, so that `visible` tells what the popup shows.
    visible: true
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
            property int duration: 0
            property bool timed: false
            property int secondsLeft: 0

            function toggle() {
                on = !on;
            }

            function chooseDuration(minutes) {
                duration = minutes;
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

    // The element's cup: the text showing either cup.
    function cupOf(item) {
        if (item.text === "󰅶" || item.text === "󰛊")
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = cupOf(item.children[i]);
            if (found)
                return found;
        }
        return null;
    }

    function test_whileOffTheElementShowsAnOutlineCupInTheSubtextColor() {
        const cup = cupOf(makeElement(false));

        compare(cup.text, "󰛊");
        compare(cup.color, theme.textMuted);
    }

    function test_whileOnTheElementShowsAFilledCupInGreen() {
        const cup = cupOf(makeElement(true));

        compare(cup.text, "󰅶");
        compare(cup.color, theme.green);
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

    // The popup's duration button labelled `label`.
    function durationButton(item, label) {
        if (item.label === label && item.activated !== undefined)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = durationButton(item.children[i], label);
            if (found)
                return found;
        }
        return null;
    }

    // The popup's text reading `text`, if it is shown.
    function shownText(item, text) {
        if (!item.visible)
            return null;
        if (item.text === text)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = shownText(item.children[i], text);
            if (found)
                return found;
        }
        return null;
    }

    function test_thePopupOffersUntilTurnedOffAndThreeDurations() {
        const item = makePopupBody(false);

        verify(durationButton(item, "Until turned off"));
        verify(durationButton(item, "30 min"));
        verify(durationButton(item, "1 h"));
        verify(durationButton(item, "2 h"));
    }

    function test_choosingADurationInThePopupSelectsIt() {
        const item = makePopupBody(true);

        durationButton(item, "1 h").activated();

        compare(item.keepAwake.duration, 60);
    }

    function test_theSelectedDurationIsShownInTheAccentColor() {
        const item = makePopupBody(false);

        compare(durationButton(item, "Until turned off").labelColor, theme.accent);
        compare(durationButton(item, "30 min").labelColor, theme.textMuted);

        item.keepAwake.chooseDuration(30);

        compare(durationButton(item, "30 min").labelColor, theme.accent);
    }

    function test_whileTimedThePopupShowsTheTimeLeft() {
        const item = makePopupBody(true);
        item.keepAwake.timed = true;
        item.keepAwake.secondsLeft = 29 * 60 + 5;

        verify(shownText(item, "29:05 left"));
    }

    function test_withoutACountdownThePopupShowsNoTimeLeft() {
        const item = makePopupBody(true);

        compare(shownText(item, "0:00 left"), null);
    }
}
