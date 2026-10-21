import Quickshell.Io
import QtQuick

QtObject {
    property alias applicationLauncherEnabled: settings.applicationLauncherEnabled
    property alias clipboardEnabled: settings.clipboardEnabled
    property alias quickSearchEnabled: settings.quickSearchEnabled
    property alias unifiedSearchEnabled: settings.unifiedSearchEnabled
    property alias commandLauncherEnabled: settings.commandLauncherEnabled
    property alias quickSettingsEnabled: settings.quickSettingsEnabled
    property alias screenCaptureEnabled: settings.screenCaptureEnabled
    property alias controlCenterEnabled: settings.controlCenterEnabled
    property alias launcherRecentLimit: settings.launcherRecentLimit
    property alias clipboardImagePreviewsEnabled: settings.clipboardImagePreviewsEnabled

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("plugins.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property bool applicationLauncherEnabled: true
            property bool clipboardEnabled: true
            property bool quickSearchEnabled: true
            property bool unifiedSearchEnabled: true
            property bool commandLauncherEnabled: true
            property bool quickSettingsEnabled: true
            property bool screenCaptureEnabled: true
            property bool controlCenterEnabled: true
            property int launcherRecentLimit: 20
            property bool clipboardImagePreviewsEnabled: true
        }
    }
}
