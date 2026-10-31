import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// A slider of the control center (volume, brightness, temperature): its icon
// and label on the left, its value on the right, over a track filled in its
// color up to the value.
TestCase {
    name: "ControlSlider"
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
        readonly property var motion: Motion.motion(true)
    }

    Component {
        id: slider

        Panels.ControlSlider {
            appearance: barAppearance
            width: 200
            label: "Volume"
            icon: "󰕾"
            accentColor: theme.blue
            valueText: "40%"
            from: 0
            to: 1
            value: 0.4
        }
    }

    function textOf(item, text) {
        if (item.text === text)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = textOf(item.children[i], text);
            if (found)
                return found;
        }
        return null;
    }

    function make(properties) {
        return createTemporaryObject(slider, this, properties || {});
    }

    function test_aSliderShowsItsIconAndLabelAndItsValue() {
        const item = make();

        verify(textOf(item, "󰕾  Volume") !== null);
        compare(textOf(item, "40%").color, theme.textMuted);
    }

    function test_aSliderShowsItsNewValueText() {
        const item = make();

        item.valueText = "Muted";
        verify(textOf(item, "Muted") !== null);
    }

    function test_aSliderKeepsItsValueWithinItsRange() {
        const item = make({ from: 2500, to: 6000, value: 9000 });

        compare(item.value, 6000);
    }
}
