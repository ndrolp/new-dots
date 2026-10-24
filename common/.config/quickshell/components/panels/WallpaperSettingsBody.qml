import QtQuick
import "../../config" as Config
import "." as Panels

// The Wallpapers section without Hyprland: `displays` are the connected
// monitors, each { description, portrait }, so it can be built and tested
// outside of the shell. The wallpaper lists are the `wallpapers` folders.
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

    function ensureWallpaperMonitor() {
        if (!displays.some(display => display.description === selectedWallpaperMonitor))
            selectedWallpaperMonitor = displays.length > 0 ? displays[0].description : "";
    }

    Component.onCompleted: ensureWallpaperMonitor()
    onDisplaysChanged: ensureWallpaperMonitor()

    Row {
        spacing: 6

        Repeater {
            model: ["Selection", "Locations", "Schedule"]

            delegate: Rectangle {
                required property string modelData

                width: viewLabel.implicitWidth + 20
                height: 30
                radius: root.appearance.radius
                color: root.wallpaperView === modelData
                    ? theme.accent : viewHover.hovered
                        ? theme.surfaceHover : theme.backgroundSecondary

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                HoverHandler {
                    id: viewHover
                }

                Text {
                    id: viewLabel

                    anchors.centerIn: parent
                    text: modelData
                    color: root.wallpaperView === modelData ? theme.background : theme.text
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }

                TapHandler {
                    onTapped: root.wallpaperView = modelData
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 8
        visible: root.wallpaperView === "Locations"

        Text {
            text: "WALLPAPER FOLDERS"
            color: theme.textMuted
            font.pixelSize: 11
            font.bold: true
        }

        SettingsInput {
            width: parent.width
            appearance: root.appearance
            text: root.wallpapers.horizontalFolder
            placeholderText: "Horizontal wallpaper folder"
            onTextEdited: root.wallpapers.horizontalFolder = text
        }

        SettingsInput {
            width: parent.width
            appearance: root.appearance
            text: root.wallpapers.verticalFolder
            placeholderText: "Vertical wallpaper folder"
            onTextEdited: root.wallpapers.verticalFolder = text
        }
    }

    Column {
        width: parent.width
        spacing: 10
        visible: root.wallpaperView === "Schedule"

        Text {
            text: "DYNAMIC WALLPAPERS"
            color: theme.textMuted
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            width: parent.width
            text: "Rotate each connected display through its horizontal or vertical folder. "
                + "Theme selection is not changed."
            color: theme.textMuted
            font.pixelSize: root.appearance.textSize - 2
            wrapMode: Text.Wrap
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: root.appearance.radius
            color: dynamicHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            HoverHandler {
                id: dynamicHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Enable scheduled rotation"
                color: theme.text
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 24
                radius: 12
                color: root.wallpapers.dynamicEnabled ? theme.accent : theme.border

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.wallpapers.dynamicEnabled ? parent.width - width - 3 : 3
                    width: 18
                    height: 18
                    radius: 9
                    color: theme.background

                    Behavior on x {
                        NumberAnimation { duration: 140 }
                    }
                }
            }

            TapHandler {
                onTapped: root.wallpapers.dynamicEnabled = !root.wallpapers.dynamicEnabled
            }
        }

        Row {
            width: parent.width
            spacing: 12

            Text {
                width: 130
                anchors.verticalCenter: parent.verticalCenter
                text: "INTERVAL"
                color: theme.textMuted
                font.pixelSize: 11
                font.bold: true
            }

            SettingsSlider {
                id: dynamicInterval

                width: parent.width - intervalLabel.width - 142
                anchors.verticalCenter: parent.verticalCenter
                from: 1
                to: 240
                stepSize: 1
                value: root.wallpapers.dynamicIntervalMinutes
                onMoved: root.wallpapers.dynamicIntervalMinutes = Math.round(value)
            }

            Text {
                id: intervalLabel

                width: 64
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(dynamicInterval.value) + " min"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }
        }

        Rectangle {
            width: advanceLabel.implicitWidth + 24
            height: 34
            radius: root.appearance.radius
            color: advanceHover.hovered ? theme.accentHover : theme.accent

            HoverHandler {
                id: advanceHover
            }

            Text {
                id: advanceLabel

                anchors.centerIn: parent
                text: "Advance now"
                color: theme.background
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            TapHandler {
                onTapped: root.wallpapers.advanceAll()
            }
        }
    }

    Column {
        width: parent.width
        spacing: 10
        visible: root.wallpaperView === "Selection"

        Panels.SettingsChoice {
            width: parent.width
            appearance: root.appearance
            options: root.displays.map(display => ({
                label: (display.portrait ? "󰍹 " : "󰍺 ") + display.description,
                value: display.description
            }))
            value: root.selectedWallpaperMonitor
            onChosen: description => root.selectedWallpaperMonitor = description
        }

        Text {
            text: root.selectedWallpaperMonitor === ""
                ? "No monitors configured"
                : root.selectedPortrait
                    ? "VERTICAL WALLPAPERS" : "HORIZONTAL WALLPAPERS"
            color: theme.textMuted
            font.pixelSize: 11
            font.bold: true
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
