import QtQuick
import QtTest
import "../components/panels" as Panels

// A popup's reveal waits until its freshly mapped window has drawn its first
// frames, so the slow first frames land while it is still transparent instead
// of cutting the start of the animation. Opening again while the window is
// still on screen (mid-close) is ready at once.
TestCase {
    name: "PopupWarmUp"
    width: 100
    height: 100
    when: windowShown
    visible: true

    Component {
        id: warmUpComponent

        Panels.PopupWarmUp {}
    }

    function warmUp() {
        return createTemporaryObject(warmUpComponent, this);
    }

    function test_closedIsNotReady() {
        const popup = warmUp();
        popup.mapped = true;
        wait(100);
        verify(!popup.ready);
    }

    function test_openButNotMappedIsNotReady() {
        const popup = warmUp();
        popup.open = true;
        wait(100);
        verify(!popup.ready);
    }

    function test_itIsReadyFramesAfterMapping() {
        const popup = warmUp();
        popup.open = true;
        popup.mapped = true;
        verify(!popup.ready);
        tryVerify(() => popup.ready, 1000);
    }

    function test_closingIsNotReady() {
        const popup = warmUp();
        popup.open = true;
        popup.mapped = true;
        tryVerify(() => popup.ready, 1000);

        popup.open = false;
        verify(!popup.ready);
    }

    function test_reopeningWhileMappedIsReadyAtOnce() {
        const popup = warmUp();
        popup.open = true;
        popup.mapped = true;
        tryVerify(() => popup.ready, 1000);
        popup.open = false;

        popup.open = true;
        verify(popup.ready);
    }

    function test_reopeningAfterUnmappingWarmsUpAgain() {
        const popup = warmUp();
        popup.open = true;
        popup.mapped = true;
        tryVerify(() => popup.ready, 1000);
        popup.open = false;
        popup.mapped = false;

        popup.open = true;
        popup.mapped = true;
        verify(!popup.ready);
        tryVerify(() => popup.ready, 1000);
    }
}
