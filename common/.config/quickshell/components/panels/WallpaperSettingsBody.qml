import QtQuick
import "../../config" as Config
import "." as Panels

// The Wallpapers section without Hyprland: `displays` are the connected
// monitors, each { description, name, portrait }, so it can be built and
// tested outside of the shell. The wallpaper lists are the `wallpapers` folders.
Column {
    id: root

    property var appearance
    property var wallpapers
    property var displays: []
    property string wallpaperView: "Selection"
    property string selectedWallpaperMonitor: ""
    readonly property bool selectedPortrait: isPortraitMonitor(selectedWallpaperMonitor)

    width: parent ? parent.width : 0
    spacing: 10

    Config.Theme {
        id: theme
    }

    function isPortraitMonitor(monitorDescription) {
        const display = displays.find(display => display.description === monitorDescription);
        return display !== undefined && display.portrait;
    }

    Panels.SettingsChoice {
        width: Math.min(parent.width, 360)
        appearance: root.appearance
        options: ["Selection", "Locations", "Schedule"].map(view => ({ label: view, value: view }))
        value: root.wallpaperView
        onChosen: view => root.wallpaperView = view
    }

    Column {
        width: parent.width
        spacing: 8
        visible: root.wallpaperView === "Locations"

        Panels.SettingsHeading {
            width: parent.width
            appearance: root.appearance
            text: "Wallpaper folders"
            topPadding: 4
        }

        SettingsInput {
            width: parent.width
            appearance: root.appearance
            text: root.wallpapers.horizontalFolder
            placeholderText: "Horizontal wallpaper folder"
            onEdited: text => root.wallpapers.horizontalFolder = text
        }

        SettingsInput {
            width: parent.width
            appearance: root.appearance
            text: root.wallpapers.verticalFolder
            placeholderText: "Vertical wallpaper folder"
            onEdited: text => root.wallpapers.verticalFolder = text
        }
    }

    Column {
        width: parent.width
        spacing: 10
        visible: root.wallpaperView === "Schedule"

        Panels.SettingsHeading {
            width: parent.width
            appearance: root.appearance
            text: "Dynamic wallpapers"
            topPadding: 4
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: root.appearance
            text: "Rotate each connected display through its horizontal or vertical folder. "
                + "Theme selection is not changed."
        }

        Panels.SettingsSwitchRow {
            width: parent.width
            appearance: root.appearance
            label: "Enable scheduled rotation"
            checked: root.wallpapers.dynamicEnabled
            onToggled: root.wallpapers.dynamicEnabled = !root.wallpapers.dynamicEnabled
        }

        Panels.SettingsNumber {
            width: Math.min(parent.width, 360)
            appearance: root.appearance
            label: "Interval (minutes)"
            from: 1
            to: 240
            value: root.wallpapers.dynamicIntervalMinutes
            onEdited: minutes => root.wallpapers.dynamicIntervalMinutes = minutes
        }

        Panels.SettingsButton {
            appearance: root.appearance
            label: "Advance now"
            onActivated: root.wallpapers.advanceAll()
        }
    }

    Column {
        width: parent.width
        spacing: 10
        visible: root.wallpaperView === "Selection"

        Panels.SettingsMonitorChoice {
            width: parent.width
            appearance: root.appearance
            displays: root.displays
            value: root.selectedWallpaperMonitor
            onChosen: description => root.selectedWallpaperMonitor = description
        }

        Panels.SettingsHeading {
            width: parent.width
            appearance: root.appearance
            text: root.selectedPortrait ? "Vertical wallpapers" : "Horizontal wallpapers"
            topPadding: 4
            visible: root.selectedWallpaperMonitor !== ""
        }

        Panels.SettingsHint {
            width: parent.width
            appearance: root.appearance
            text: "No monitors configured"
            visible: root.selectedWallpaperMonitor === ""
        }

        GridView {
            id: wallpaperGrid

            readonly property bool portrait: root.selectedPortrait

            width: parent.width
            height: 250
            cellWidth: 128
            cellHeight: 112
            clip: true
            interactive: true
            model: portrait ? root.wallpapers.verticalWallpapers : root.wallpapers.horizontalWallpapers

            delegate: Rectangle {
                id: wallpaperTile

                required property string fileName
                readonly property string wallpaperPath:
                    (wallpaperGrid.portrait
                        ? root.wallpapers.verticalFolder
                        : root.wallpapers.horizontalFolder)
                    + "/" + fileName
                readonly property bool assigned:
                    root.wallpapers.pathFor(root.selectedWallpaperMonitor) === wallpaperPath

                // Only an outline: the accent marks the monitor's wallpaper.
                width: wallpaperGrid.cellWidth - 8
                height: wallpaperGrid.cellHeight - 8
                radius: root.appearance.radius
                color: "transparent"
                border.color: assigned ? theme.accent : tileHover.hovered ? theme.textMuted : theme.border
                border.width: assigned ? 2 : 1

                HoverHandler {
                    id: tileHover
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Math.max(0, parent.radius - 2)
                    clip: true
                    color: "transparent"

                    Image {
                        id: wallpaperPreview

                        anchors.fill: parent
                        source: "file://" + wallpaperTile.wallpaperPath
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Panels.SettingsHint {
                        anchors.centerIn: parent
                        visible: wallpaperPreview.status === Image.Error
                        appearance: root.appearance
                        text: "Preview unavailable"
                    }
                }

                Panels.Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    text: wallpaperTile.fileName
                    color: theme.text
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 2
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onClicked: root.wallpapers.setWallpaper(
                        root.selectedWallpaperMonitor, wallpaperTile.wallpaperPath)
                }
            }
        }
    }
}
