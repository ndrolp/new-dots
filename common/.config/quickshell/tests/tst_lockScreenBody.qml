import QtQuick
import QtTest
import "../components/lock" as Lock
import "../config" as Config

// What the lock screen shows on one monitor. Lock.qml puts it on every
// monitor with WlSessionLock and checks the password with PamContext, which
// don't load here, so these tests stop at the password it asks to check.
TestCase {
    name: "LockScreenBody"
    width: 800
    height: 600
    // Shown, so that `visible` tells what the lock screen shows.
    visible: true
    when: windowShown

    Component {
        id: bodyComponent

        Lock.LockScreenBody {
            width: 800
            height: 600
            now: new Date(2026, 9, 28, 9, 5)
        }
    }

    Config.Theme {
        id: theme
    }

    SignalSpy {
        id: submitted
        signalName: "passwordSubmitted"
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function shown(item, text) {
        return all(item, child => child.text === text && child.visible).length > 0;
    }

    function field(item) {
        return all(item, child => child.echoMode === TextInput.Password)[0];
    }

    function make(properties) {
        const body = createTemporaryObject(bodyComponent, this, properties || {});
        submitted.clear();
        submitted.target = body;
        return body;
    }

    function test_everyMonitorShowsTheClockAndTheDate() {
        const body = make({ showsPasswordField: false });
        verify(shown(body, "09:05"));
        verify(shown(body, "Wednesday, October 28"));
    }

    function test_onlyTheFocusedMonitorShowsThePasswordField() {
        verify(!field(make({ showsPasswordField: false })).visible);
        verify(field(make({ showsPasswordField: true })).visible);
    }

    function test_enterAsksToCheckThePasswordAndClearsTheField() {
        const body = make({ showsPasswordField: true });
        const input = field(body);

        input.forceActiveFocus();
        keyClick("h");
        keyClick("i");
        keyClick(Qt.Key_Return);

        compare(submitted.count, 1);
        compare(submitted.signalArguments[0][0], "hi");
        compare(input.text, "");
    }

    function test_whileAPasswordIsCheckedTheFieldTakesNothing() {
        const body = make({ showsPasswordField: true, checking: true });
        const input = field(body);

        input.forceActiveFocus();
        keyClick("h");
        keyClick(Qt.Key_Return);

        compare(input.text, "");
        compare(submitted.count, 0);
        verify(shown(body, "Checking…"));
    }

    function test_theErrorShowsUnderThePasswordField() {
        const body = make({ showsPasswordField: true, error: "Wrong password" });
        verify(shown(body, "Wrong password"));
    }

    function test_theErrorOnlyShowsWithThePasswordField() {
        const body = make({ showsPasswordField: false, error: "Wrong password" });
        verify(!shown(body, "Wrong password"));
    }

    // The wallpaper as the lock screen shows it: blurred.
    function blurredWallpaper(item) {
        return all(item, child => child.blurEnabled === true && child.source instanceof Image
            && child.visible)[0] || null;
    }

    function test_theMonitorsWallpaperShowsBlurredBehindTheClock() {
        const blurred = blurredWallpaper(make({ wallpaper: "/walls/forest.jpg" }));
        verify(blurred);
        verify(blurred.blur > 0);
        compare(blurred.source.source.toString(), "file:///walls/forest.jpg");
    }

    function test_withoutAWallpaperOnlyTheThemeShows() {
        verify(!blurredWallpaper(make({ wallpaper: "" })));
    }

    // Light and dark wallpapers alike sit under the theme's background, so
    // the theme's text stays readable on them.
    function test_theThemesBackgroundTintsTheWallpaper() {
        const body = make({ wallpaper: "/walls/forest.jpg" });
        const tint = all(body, child => child !== body && child.color !== undefined
            && Qt.colorEqual(child.color, theme.background) && child.visible
            && child.width === body.width && child.height === body.height)[0];
        verify(tint);
        verify(tint.opacity > 0 && tint.opacity < 1);
    }
}
