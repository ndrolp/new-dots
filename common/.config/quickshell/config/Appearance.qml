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
    property alias workspaceGlyphsEnabled: settings.workspaceGlyphsEnabled
    property alias hideEmptyWorkspaces: settings.hideEmptyWorkspaces
    property alias workspaceGlyphs: settings.workspaceGlyphs
    property alias pillsTransparent: settings.pillsTransparent
    property alias transparentBarTopMargin: settings.transparentBarTopMargin
    property alias transparentBarSlanted: settings.transparentBarSlanted
    property alias statusIsland: settings.statusIsland
    property alias statusIslandRadius: settings.statusIslandRadius
    property alias backgroundClockEnabled: settings.backgroundClockEnabled
    property alias backgroundClockCalendarEnabled: settings.backgroundClockCalendarEnabled
    property alias backgroundClockPosition: settings.backgroundClockPosition
    property alias backgroundClockSize: settings.backgroundClockSize
    property alias backgroundClockOpacity: settings.backgroundClockOpacity
    property alias backgroundClockDateFormat: settings.backgroundClockDateFormat
    property alias desktopMediaEnabled: settings.desktopMediaEnabled
    property alias desktopMediaPosition: settings.desktopMediaPosition
    property alias desktopSystemEnabled: settings.desktopSystemEnabled
    property alias desktopSystemPosition: settings.desktopSystemPosition
    property alias desktopCalendarEnabled: settings.desktopCalendarEnabled
    property alias desktopCalendarPosition: settings.desktopCalendarPosition
    property alias desktopNetworkEnabled: settings.desktopNetworkEnabled
    property alias desktopNetworkPosition: settings.desktopNetworkPosition
    property alias desktopWeatherEnabled: settings.desktopWeatherEnabled
    property alias desktopWeatherPosition: settings.desktopWeatherPosition
    property alias desktopWeatherLocation: settings.desktopWeatherLocation
    property alias notificationPopupLocation: settings.notificationPopupLocation
    property alias doNotDisturb: settings.doNotDisturb
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
            property bool workspaceGlyphsEnabled: false
            property bool hideEmptyWorkspaces: false
            property var workspaceGlyphs: [
                "", "", "", "", "", "", "", "", "", "",
                "", "", "", "", "", "", "", "", "", ""
            ]
            property bool pillsTransparent: false
            property int transparentBarTopMargin: 0
            property bool transparentBarSlanted: false
            property bool statusIsland: false
            property int statusIslandRadius: 12
            property bool backgroundClockEnabled: true
            property bool backgroundClockCalendarEnabled: false
            property string backgroundClockPosition: "center"
            property int backgroundClockSize: 96
            property int backgroundClockOpacity: 100
            property string backgroundClockDateFormat: "full"
            property bool desktopMediaEnabled: false
            property string desktopMediaPosition: "bottom-left"
            property bool desktopSystemEnabled: false
            property string desktopSystemPosition: "top-right"
            property bool desktopCalendarEnabled: false
            property string desktopCalendarPosition: "top-left"
            property bool desktopNetworkEnabled: false
            property string desktopNetworkPosition: "bottom-right"
            property bool desktopWeatherEnabled: false
            property string desktopWeatherPosition: "top-center"
            property string desktopWeatherLocation: "Ourense, ES"
            property string notificationPopupLocation: "top-center"
            property bool doNotDisturb: false
            property bool barTransparent: false
        }
    }
}
