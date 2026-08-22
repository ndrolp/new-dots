import QtQuick
import Quickshell.Io

QtObject {
    property alias barHeight: settings.barHeight
    property alias horizontalPadding: settings.horizontalPadding
    property alias spacing: settings.spacing
    property alias radius: settings.radius
    property alias workspaceButtonSize: settings.workspaceButtonSize
    property alias textSize: settings.textSize
    property alias archButtonHorizontalPadding: settings.archButtonHorizontalPadding
    property alias activeWorkspaceHorizontalPadding: settings.activeWorkspaceHorizontalPadding
    property alias pillVerticalPadding: settings.pillVerticalPadding
    property alias workspacePadding: settings.workspacePadding
    property alias pillsTransparent: settings.pillsTransparent
    property alias transparentBarTopMargin: settings.transparentBarTopMargin
    property alias transparentBarSlanted: settings.transparentBarSlanted
    property alias notificationPopupLocation: settings.notificationPopupLocation
    property alias barTransparent: settings.barTransparent

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("appearance.json")
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

            property int barHeight: 32
            property int horizontalPadding: 12
            property int spacing: 8
            property int radius: 8
            property int workspaceButtonSize: 20
            property int textSize: 14
            property int archButtonHorizontalPadding: 6
            property int activeWorkspaceHorizontalPadding: 6
            property int pillVerticalPadding: 3
            property int workspacePadding: 4
            property bool pillsTransparent: false
            property int transparentBarTopMargin: 0
            property bool transparentBarSlanted: false
            property string notificationPopupLocation: "top-center"
            property bool barTransparent: false
        }
    }
}
