import QtQuick
import QtTest
import "../components/bar"

// How much taller a capsule's bar window is held for a popup inside: as much
// as the tallest popup has needed, at once, and never less, since Hyprland
// stretches a shrinking layer's last picture to its old size while it
// animates the change.
TestCase {
    name: "CapsuleWindowHold"

    Component {
        id: holdComponent

        CapsuleWindowHold {}
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

    // Closing the popup, or a smaller one, leaves the window as tall.
    function test_itNeverShrinks() {
        const window = hold();
        window.needed = 300;

        window.needed = 120;
        window.needed = 0;
        wait(50);
        compare(window.held, 300);
    }

    function test_aTallerPopupGrowsItFurther() {
        const window = hold();
        window.needed = 300;
        window.needed = 0;

        window.needed = 450;
        compare(window.held, 450);
    }
}
