import QtQuick
import "BarProfileModel.js" as BarProfileModel

// Brings appearance.json and monitors.json to the current schema version once
// both are loaded. Already migrated files are left untouched.
QtObject {
    id: root

    required property var appearance
    required property var monitors

    readonly property bool ready: appearance.loaded && monitors.loaded

    function run() {
        if (!ready)
            return;

        const appearanceState = appearance.rawState();
        if (!appearanceState || !BarProfileModel.needsMigration(appearanceState))
            return;

        const migrated = BarProfileModel.migrate(appearanceState, monitors.rawState() || {});
        console.info("Migrating settings to schema version " + BarProfileModel.schemaVersion);
        // Monitors first: the appearance file carries the schema version.
        monitors.applyMigratedState(migrated.monitors);
        appearance.applyMigratedState(migrated.appearance);
    }

    onReadyChanged: run()
    Component.onCompleted: run()
}
