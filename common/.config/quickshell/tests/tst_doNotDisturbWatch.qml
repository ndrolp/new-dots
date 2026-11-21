import QtQuick
import QtTest
import "../components/panels" as Panels

// Do Not Disturb as a change event: turning it on or off, from anywhere,
// shows it; the setting being read as the shell starts doesn't.
TestCase {
    name: "DoNotDisturbWatch"

    Component {
        id: appearanceComponent

        QtObject {
            property bool loaded: false
            property bool doNotDisturb: false
        }
    }

    Component {
        id: watchComponent

        Panels.DoNotDisturbWatch {
            property var shown: []

            onToggled: change => shown.push(change)
        }
    }

    function watch(appearance) {
        return createTemporaryObject(watchComponent, this, { appearance: appearance });
    }

    function shown(watch) {
        return watch.shown.map(change => change.kind + ":" + change.on);
    }

    function test_turningItOnAndOffShowsEachTime() {
        const appearance = createTemporaryObject(appearanceComponent, this, { loaded: true });
        const watched = watch(appearance);

        appearance.doNotDisturb = true;
        appearance.doNotDisturb = false;

        compare(shown(watched), ["doNotDisturb:true", "doNotDisturb:false"]);
    }

    // appearance.json is read after the shell starts: the saved setting
    // arriving then isn't a change.
    function test_theSavedSettingReadAtStartDoesNotShow() {
        const appearance = createTemporaryObject(appearanceComponent, this);
        const watched = watch(appearance);

        appearance.doNotDisturb = true;
        appearance.loaded = true;

        compare(shown(watched), []);

        appearance.doNotDisturb = false;

        compare(shown(watched), ["doNotDisturb:false"]);
    }

    function test_anAlreadyLoadedSettingDoesNotShow() {
        const appearance = createTemporaryObject(appearanceComponent, this,
            { loaded: true, doNotDisturb: true });
        const watched = watch(appearance);

        compare(shown(watched), []);
    }
}
