import QtQuick
import QtTest
import "../components/bar"

// How much taller a capsule's bar window is held for a popup inside: as much
// as the popup needs as soon as it needs it, and only after the capsule has
// finished shrinking when it needs less, so the window isn't resized every
// frame and doesn't cut the capsule off while it shrinks.
TestCase {
    name: "CapsuleWindowHold"

    Component {
        id: holdComponent

        CapsuleWindowHold {
            shrinkDelay: 100
        }
    }

    function hold() {
        return createTemporaryObject(holdComponent, this);
    }

    function test_itHoldsNothingAtFirst() {
        compare(hold().held, 0);
    }

    function test_itGrowsAtOnce() {
        const window = hold();

        window.needed = 300;
        compare(window.held, 300);
    }

    function test_itShrinksOnlyAfterTheDelay() {
        const window = hold();
        window.needed = 300;

        window.needed = 0;
        wait(40);
        compare(window.held, 300);
        tryCompare(window, "held", 0, 300);
    }

    // Needing more again while waiting to shrink grows it at once and calls
    // the shrink off.
    function test_needingMoreAgainCallsTheShrinkOff() {
        const window = hold();
        window.needed = 300;
        window.needed = 100;

        window.needed = 400;
        compare(window.held, 400);
        wait(200);
        compare(window.held, 400);
    }

    // Shrinking in steps waits for the last one, then shrinks to it.
    function test_itShrinksOnceToWhatIsLastNeeded() {
        const window = hold();
        window.needed = 300;

        window.needed = 200;
        wait(60);
        window.needed = 120;
        wait(60);
        compare(window.held, 300);
        tryCompare(window, "held", 120, 300);
    }
}
