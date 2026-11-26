import QtQuick
import QtTest
import "../components/bar" as Bar

// The item of a bar element that can be live: where it goes, how large it
// is and how it shows and goes, fading as a live element.
TestCase {
    name: "LiveCapableItem"
    // Shown, so that `visible` tells whether it is drawn.
    visible: true
    when: windowShown
    width: 400
    height: 100

    QtObject {
        id: profile

        property string barPosition: "top"
        property var motion: ({ medium: 100000, long: 100000, easing: 0 })
    }

    // Where the bar draws its elements: media is shown or not, live or not,
    // at (30, 40) and drawn at 11 px.
    QtObject {
        id: bar

        property bool mediaShown: true
        property bool mediaLive: true

        function itemVisible(element) { return element === "media" && mediaShown; }
        function live(element) { return element === "media" && mediaLive; }
        function sizes(element) { return { textSize: 11, iconSize: 11, thickness: 21 }; }
        function elementX(element) { return 30; }
        function elementY(element) { return 40; }
        // How media looks in the capsule's row now, mid-entry.
        function rowLook(element) {
            return element === "media" ? { opacity: 0.5, scale: 0.9, slide: -3 } : null;
        }
    }

    Component {
        id: media

        Bar.LiveCapableItem {
            id: holder

            appearance: profile
            element: "media"
            items: bar

            Rectangle {
                width: 80
                height: holder.sizes.thickness
            }
        }
    }

    function init() {
        profile.motion = { medium: 100000, long: 100000, easing: 0 };
        bar.mediaShown = true;
        bar.mediaLive = true;
    }

    function test_itSitsAtItsPlaceAsLargeAsItsItem() {
        const item = createTemporaryObject(media, this);

        compare([item.x, item.y, item.width, item.height], [30, 40, 80, 21]);
        verify(item.visible);
        compare(item.opacity, 1);
    }

    // As a live element it fades out, still visible, so it disappears
    // gradually instead of at once.
    function test_aLiveElementFadesOut() {
        const item = createTemporaryObject(media, this);

        bar.mediaShown = false;
        verify(!item.shown);
        verify(item.visible);
        verify(item.opacity > 0);
    }

    // It keeps its room beside the pills until its fade-out ends, so the
    // pills and the capsule close up as it disappears instead of cutting
    // its fade-out short.
    function test_aLiveElementKeepsItsRoomUntilItHasFadedOut() {
        profile.motion = { medium: 200, long: 200, easing: 0 };
        const item = createTemporaryObject(media, this);
        verify(item.takesRoom);

        bar.mediaShown = false;
        verify(item.takesRoom);
        tryCompare(item, "takesRoom", false, 2000);
        compare(item.opacity, 0);
    }

    // With reduce motion it goes at once.
    function test_aLiveElementGoesAtOnceWithReduceMotion() {
        profile.motion = { medium: 0, long: 0, easing: 0 };
        const item = createTemporaryObject(media, this);

        bar.mediaShown = false;
        tryCompare(item, "visible", false, 100);
        verify(!item.takesRoom);
    }

    // In the capsule's row it looks as the row has it look (rowLook): faded,
    // scaled and slid along the bar.
    function test_inTheRowItTakesItsLook() {
        bar.mediaLive = false;
        const item = createTemporaryObject(media, this);

        compare(item.opacity, 0.5);
        compare(item.scale, 0.9);
        compare(item.transform[0].x, -3);
        compare(item.x, 30);
    }

    // Live, beside the pills, it doesn't.
    function test_liveItKeepsItsOwnLook() {
        const item = createTemporaryObject(media, this);

        compare(item.opacity, 1);
        compare(item.scale, 1);
        compare(item.transform[0].x, 0);
    }

    // Anywhere else it is hidden at once.
    function test_anyOtherElementIsHiddenAtOnce() {
        bar.mediaLive = false;
        const item = createTemporaryObject(media, this);

        bar.mediaShown = false;
        verify(!item.visible);
        compare(item.opacity, 0);
    }
}
