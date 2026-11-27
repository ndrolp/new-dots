import QtQuick
import QtTest
import "../config" as Config
import "../config/BarProfileModel.js" as BarProfileModel

// The schema migration writes appearance.json and monitors.json as the shell
// writes them otherwise: indented JSON ending in a newline.
TestCase {
    name: "SchemaMigrationFiles"

    Component {
        id: fakeFile

        QtObject {
            property bool loaded: true
            property var state: ({})
            property string written: ""

            function rawState() {
                return state;
            }

            function replaceText(text) {
                written = text;
            }
        }
    }

    Component {
        id: migrationComponent

        Config.SchemaMigration {}
    }

    function test_migratedFilesEndInANewline() {
        const appearance = createTemporaryObject(fakeFile, this,
            { state: { schemaVersion: 0, barProfiles: {} } });
        const monitors = createTemporaryObject(fakeFile, this, { state: {} });

        createTemporaryObject(migrationComponent, this,
            { appearance: appearance, monitors: monitors });

        verify(appearance.written.endsWith("}\n"), appearance.written.slice(-10));
        verify(monitors.written.endsWith("}\n"), monitors.written.slice(-10));
        verify(JSON.parse(appearance.written).schemaVersion > 0);
    }

    function trackedState(name) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../config/" + name), false);
        request.send();
        return JSON.parse(request.responseText);
    }

    // The tracked files are committed already migrated, so the shell's first
    // run doesn't rewrite them and leave the checkout changed.
    function test_theTrackedFilesNeedNoMigration() {
        const appearance = createTemporaryObject(fakeFile, this, { state: trackedState("appearance.json") });
        const monitors = createTemporaryObject(fakeFile, this, { state: trackedState("monitors.json") });

        createTemporaryObject(migrationComponent, this, { appearance: appearance, monitors: monitors });

        compare(appearance.written, "");
        compare(monitors.written, "");
    }

    // The tracked capsule profile shows only the clock at rest, the time
    // without its icon, besides its live elements.
    function test_theTrackedCapsuleShowsOnlyTheClockAtRest() {
        const profile = BarProfileModel.completeProfile(trackedState("appearance.json").barProfiles.island);
        const ids = BarProfileModel.capsulePlaceIds(profile.barElements, profile.capsulePlaces);

        compare(profile.barStyle, "capsule");
        compare(ids.shown, ["clock"]);
        compare(BarProfileModel.iconTextShown(profile.barElements, "clock", true), { icon: false, text: true });
    }

    // The tracked capsule profile puts the battery in its row on battery, or
    // live in it, so it shows there at rest while on battery.
    function test_theTrackedCapsuleShowsTheBatteryLive() {
        const profile = BarProfileModel.completeProfile(trackedState("appearance.json").barProfiles.island);

        verify(["onBattery", "liveRow"].indexOf(profile.capsulePlaces.battery) !== -1,
            profile.capsulePlaces.battery);
    }

    function test_alreadyMigratedFilesAreNotWritten() {
        const current = createTemporaryObject(fakeFile, this, { state: { schemaVersion: 0 } });
        const monitors = createTemporaryObject(fakeFile, this, { state: {} });
        createTemporaryObject(migrationComponent, this, { appearance: current, monitors: monitors });
        const migrated = JSON.parse(current.written);

        const appearance = createTemporaryObject(fakeFile, this, { state: migrated });
        const untouched = createTemporaryObject(fakeFile, this, { state: {} });
        createTemporaryObject(migrationComponent, this,
            { appearance: appearance, monitors: untouched });

        compare(appearance.written, "");
        compare(untouched.written, "");
    }
}
