import QtQuick
import QtTest
import "../components/panels" as Panels

// A window's thumbnail in the workspace overview: it lies over the window's icon
// and title once a frame has arrived, and stays out of the way until then, since
// Hyprland may never give one for a window on a hidden workspace.
// WindowFrames.qml, which captures them, needs Quickshell and isn't tested here.
TestCase {
    name: "WindowThumbnail"
    width: 200
    height: 200
    when: windowShown
    // Shown, so that `visible` says what's really on screen.
    visible: true

    // A stand-in for a ScreencopyView.
    Component {
        id: frameComponent

        Item {
            property bool hasContent: false
        }
    }

    // A frame that isn't on screen itself, as WindowFrames.qml keeps them.
    Component {
        id: paintedFrameComponent

        Rectangle {
            property bool hasContent: true

            visible: false
            width: 40
            height: 24
            color: "#ff0000"
        }
    }

    Component {
        id: thumbnailComponent

        Panels.WindowThumbnail {
            width: 100
            height: 60
        }
    }

    function thumbnailOf(frame) {
        return createTemporaryObject(thumbnailComponent, this, { frame: frame });
    }

    function test_aWindowWithoutAFrameShowsNoThumbnail() {
        verify(!thumbnailOf(null).visible);
    }

    function test_aThumbnailDrawsItsFrameAtItsOwnSize() {
        const frame = createTemporaryObject(paintedFrameComponent, this);
        const thumbnail = thumbnailOf(frame);

        waitForRendering(thumbnail);

        const image = grabImage(thumbnail);

        compare(image.red(90, 50), 255);
        compare(image.green(90, 50), 0);
    }

    function test_aFrameThatHasNotArrivedShowsNoThumbnail() {
        const frame = createTemporaryObject(frameComponent, this);

        verify(!thumbnailOf(frame).visible);
    }

    function test_aFrameThatHasArrivedShowsTheThumbnail() {
        const frame = createTemporaryObject(frameComponent, this, { hasContent: true });

        verify(thumbnailOf(frame).visible);
    }

    function test_aFrameArrivingWhileShownBringsTheThumbnailIn() {
        const frame = createTemporaryObject(frameComponent, this);
        const thumbnail = thumbnailOf(frame);

        frame.hasContent = true;

        verify(thumbnail.visible);
    }

    function test_losingTheFrameGoesBackToTheIconAndTitle() {
        const frame = createTemporaryObject(frameComponent, this, { hasContent: true });
        const thumbnail = thumbnailOf(frame);

        thumbnail.frame = null;

        verify(!thumbnail.visible);
    }
}
