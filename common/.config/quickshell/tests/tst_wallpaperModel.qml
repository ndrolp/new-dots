import QtQuick
import QtTest
import "../config/WallpaperModel.js" as WallpaperModel

// Wallpaper assignments are kept per monitor description; each monitor only
// sees the folder of its orientation.
TestCase {
    name: "WallpaperModel"

    function test_aRotatedTransformIsPortrait() {
        verify(WallpaperModel.isPortrait(1, 1920, 1080));
        verify(WallpaperModel.isPortrait(3, 1920, 1080));
    }

    function test_anUnrotatedTransformIsLandscapeWhateverTheSize() {
        verify(!WallpaperModel.isPortrait(0, 1080, 1920));
        verify(!WallpaperModel.isPortrait(2, 1080, 1920));
    }

    function test_flippedTransformsFallBackToTheSize() {
        verify(WallpaperModel.isPortrait(5, 1080, 1920));
        verify(!WallpaperModel.isPortrait(4, 1920, 1080));
    }

    function test_assigningAWallpaperKeepsTheOtherMonitors() {
        const before = { "AOC": "/a.png", "Philips": "/p.png" };

        const after = WallpaperModel.withAssignment(before, "AOC", "/b.png");

        compare(after, { "AOC": "/b.png", "Philips": "/p.png" });
        compare(before["AOC"], "/a.png");
    }

    function test_aMonitorWithoutDescriptionIsNeverAssigned() {
        const after = WallpaperModel.withAssignment({ "AOC": "/a.png" }, "", "/b.png");

        compare(after, { "AOC": "/a.png" });
    }

    function test_aStaleAssignmentWithoutDescriptionIsDropped() {
        const after = WallpaperModel.withAssignment({ "": "/old.png", "AOC": "/a.png" },
            "AOC", "/b.png");

        compare(after, { "AOC": "/b.png" });
    }

    function test_steppingWrapsAroundBothEnds() {
        compare(WallpaperModel.step(4, 1, 5), 0);
        compare(WallpaperModel.step(0, -1, 5), 4);
        compare(WallpaperModel.step(2, 1, 5), 3);
    }

    function test_steppingAnEmptyFolderStaysPut() {
        compare(WallpaperModel.step(0, 1, 0), 0);
    }
}
