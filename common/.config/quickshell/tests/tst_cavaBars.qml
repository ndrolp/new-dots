import QtQuick
import QtTest
import "../components/bar" as Bar
import "../config" as Config

// What the Cava bar element draws from the frame the shared cava prints: its
// own bar count, bar width and color, and as wide as those bars.
TestCase {
    name: "CavaBars"
    width: 400
    height: 400
    visible: true
    when: windowShown

    Config.Theme {
        id: theme
    }

    Component {
        id: cavaBars

        Bar.CavaBars {
            height: 20
        }
    }

    function bars(properties) {
        return createTemporaryObject(cavaBars, this, properties);
    }

    function drawn(item) {
        const found = [];
        for (let i = 0; i < item.children.length; i++) {
            if (item.children[i] instanceof Rectangle)
                found.push(item.children[i]);
        }
        return found;
    }

    function test_itIsAsWideAsItsBarsOnePixelApart() {
        compare(bars({ barCount: 12, barWidth: 3 }).implicitWidth, 47);
        compare(bars({ barCount: 6, barWidth: 1 }).implicitWidth, 11);
        compare(bars({ barCount: 32, barWidth: 8 }).implicitWidth, 287);
    }

    function test_itDrawsItsOwnBarCountFromALargerFrame() {
        const item = bars({ barCount: 2, frame: [0, 0.5, 1, 0.25] });

        compare(item.heights, [0.5, 1]);
        compare(drawn(item).length, 2);
    }

    function test_withoutAFrameItsBarsAreFlat() {
        compare(bars({ barCount: 3, frame: [] }).heights, [0, 0, 0]);
    }

    function test_itsColorIsTheThemeColorItNames() {
        const item = bars({ barCount: 2, colorName: "red" });

        compare(item.color, theme.red);
        compare(drawn(item)[0].color, theme.red);
        compare(bars({ barCount: 2 }).color, theme.blue);
    }
}
