import QtQuick
import "SchemaMigrations.js" as SchemaMigrations

// Brings appearance.json and monitors.json to the current schema version once
// both are loaded. Already migrated files are left untouched. The files are
// written as the shell's adapters write them: indented, ending in a newline.
QtObject {
    id: root

    required property var appearance
    required property var monitors

    readonly property bool ready: appearance.loaded && monitors.loaded

    function fileText(state) {
        return JSON.stringify(state, null, 4) + "\n";
    }

    function run() {
        if (!ready)
            return;

        const appearanceState = appearance.rawState();
        if (!appearanceState || !SchemaMigrations.needsMigration(appearanceState))
            return;

        const migrated = SchemaMigrations.migrate(appearanceState, monitors.rawState() || {});
        console.info("Migrating settings to schema version " + SchemaMigrations.schemaVersion);
        // Monitors first: the appearance file carries the schema version.
        monitors.replaceText(fileText(migrated.monitors));
        appearance.replaceText(fileText(migrated.appearance));
    }

    onReadyChanged: run()
    Component.onCompleted: run()
}
