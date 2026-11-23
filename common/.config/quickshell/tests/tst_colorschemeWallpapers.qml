import QtQuick
import QtTest
import "../config/WallpaperModel.js" as WallpaperModel

// Applying a colorscheme moves the wallpaper folders to its own, falling back
// to Default for an orientation it has none for, and gives every monitor one
// of its wallpapers, apart from the other monitors' where there are enough.
TestCase {
    name: "ColorschemeWallpapers"

    readonly property string root: "/w"

    // Always the first one left.
    function first() {
        return 0;
    }

    function test_theFoldersAreTheColorschemesOwn() {
        const listed = ["/w/nord/Horizontal/a.png", "/w/nord/Vertical/b.png"];

        const folders = WallpaperModel.colorschemeFolders(root, "nord", listed);

        compare(folders, { horizontal: "/w/nord/Horizontal", vertical: "/w/nord/Vertical" });
    }

    function test_anOrientationWithoutWallpapersFallsBackToDefault() {
        const listed = ["/w/nord/Horizontal/a.png", "/w/Default/Vertical/b.png"];

        const folders = WallpaperModel.colorschemeFolders(root, "nord", listed);

        compare(folders, { horizontal: "/w/nord/Horizontal", vertical: "/w/Default/Vertical" });
    }

    function test_aColorschemeWithNoFolderUsesDefault() {
        const folders = WallpaperModel.colorschemeFolders(root, "dracula", ["/w/Default/Horizontal/a.png"]);

        compare(folders, { horizontal: "/w/Default/Horizontal", vertical: "/w/Default/Vertical" });
    }

    function test_theWallpapersInAFolderAreOnlyItsOwnFiles() {
        const listed = ["/w/nord/Horizontal/a.png", "/w/nord/Horizontal/b.png", "/w/Default/Horizontal/c.png"];

        compare(WallpaperModel.wallpapersIn("/w/nord/Horizontal", listed),
            ["/w/nord/Horizontal/a.png", "/w/nord/Horizontal/b.png"]);
    }

    function test_eachMonitorGetsAWallpaperOfItsOrientation() {
        const monitors = [{ description: "AOC", portrait: false }, { description: "Philips", portrait: true }];

        const picked = WallpaperModel.spread(monitors, ["/h1.png"], ["/v1.png"], first);

        compare(picked, { "AOC": "/h1.png", "Philips": "/v1.png" });
    }

    function test_monitorsOfTheSameOrientationGetDifferentWallpapers() {
        const monitors = [{ description: "AOC", portrait: false }, { description: "Samsung", portrait: false }];

        const picked = WallpaperModel.spread(monitors, ["/h1.png", "/h2.png"], [], first);

        compare(picked, { "AOC": "/h1.png", "Samsung": "/h2.png" });
    }

    function test_withTooFewWallpapersMonitorsShareOne() {
        const monitors = [{ description: "AOC", portrait: false }, { description: "Samsung", portrait: false }];

        const picked = WallpaperModel.spread(monitors, ["/h1.png"], [], first);

        compare(picked, { "AOC": "/h1.png", "Samsung": "/h1.png" });
    }

    function test_aMonitorWithNoWallpaperOfItsOrientationIsLeftAlone() {
        const monitors = [{ description: "Philips", portrait: true }, { description: "", portrait: false }];

        compare(WallpaperModel.spread(monitors, ["/h1.png"], [], first), {});
    }

    function test_thePickComesFromTheRandomSource() {
        const monitors = [{ description: "AOC", portrait: false }];

        const picked = WallpaperModel.spread(monitors, ["/h1.png", "/h2.png", "/h3.png"], [], () => 0.99);

        compare(picked, { "AOC": "/h3.png" });
    }
}
