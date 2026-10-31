import QtQuick
import QtTest
import "../modules/SwitchTo.js" as SwitchTo

// One part of the shell opening another in its place: a control center tile
// opening the power menu, quick settings opening the control center.
TestCase {
    name: "SwitchTo"

    function part(available) {
        return {
            available: available,
            shown: 0,
            show() {
                this.shown++;
            }
        };
    }

    function test_closesThisPartAndShowsTheOther() {
        const other = part(true);
        let closed = 0;

        SwitchTo.switchTo(() => closed++, other);

        compare([closed, other.shown], [1, 1]);
    }

    // Its plugin is off: this part stays open.
    function test_anUnavailablePartLeavesThisOneOpen() {
        const other = part(false);
        let closed = 0;

        SwitchTo.switchTo(() => closed++, other);

        compare([closed, other.shown], [0, 0]);
    }
}
