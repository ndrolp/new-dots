import QtQuick
import QtTest
import "../components/IconSource.js" as IconSource

// App and tray icons fall back to a generic app icon from the icon theme
// instead of the missing icon checkerboard.
TestCase {
    name: "IconSource"

    function test_aNamedIconFallsBackToTheGenericAppIcon() {
        compare(IconSource.forName("firefox"),
            "image://icon/firefox?fallback=application-x-executable");
    }

    function test_noNameShowsTheGenericAppIcon() {
        compare(IconSource.forName(""), "image://icon/application-x-executable");
        compare(IconSource.forName(undefined), "image://icon/application-x-executable");
    }

    function test_anAbsolutePathIsLoadedAsAFile() {
        compare(IconSource.forName("/opt/app/icon.png"), "file:///opt/app/icon.png");
    }

    function test_aUrlIsLeftAsIs() {
        compare(IconSource.forName("file:///tmp/avatar.png"), "file:///tmp/avatar.png");
    }

    function test_aNamedTrayIconFallsBackToTheGenericAppIcon() {
        compare(IconSource.forTray("image://icon/nm-applet"),
            "image://icon/nm-applet?fallback=application-x-executable");
    }

    function test_aTrayIconWithItsOwnPathIsLeftAsIs() {
        compare(IconSource.forTray("image://icon/steam?path=/usr/share/pixmaps"),
            "image://icon/steam?path=/usr/share/pixmaps");
    }

    function test_aTrayPixmapIsLeftAsIs() {
        compare(IconSource.forTray("image://qspixmap/discord/0"), "image://qspixmap/discord/0");
    }

    function test_aTrayItemWithNoIconShowsTheGenericAppIcon() {
        compare(IconSource.forTray(""), "image://icon/application-x-executable");
    }
}
