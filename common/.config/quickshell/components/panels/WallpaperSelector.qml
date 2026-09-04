import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var wallpapers
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: selector

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property string monitorDescription: monitor && monitor.description !== ""
            ? monitor.description : modelData.name
        readonly property bool portrait: monitor
            && ((Number(monitor.lastIpcObject.transform) === 1)
                || (Number(monitor.lastIpcObject.transform) === 3)
                || (Number(monitor.lastIpcObject.transform) !== 0
                    && Number(monitor.lastIpcObject.transform) !== 2
                    && monitor.height > monitor.width))
        readonly property string wallpaperFolder: portrait
            ? root.wallpapers.verticalFolder : root.wallpapers.horizontalFolder
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor
            && monitor && Hyprland.focusedWorkspace.monitor.name === monitor.name

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-wallpaper-selector"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        FolderListModel {
            id: selectorWallpapers

            folder: selector.wallpaperFolder === ""
                ? "" : Qt.resolvedUrl(selector.wallpaperFolder)
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
            showDirs: false
        }

        Config.Theme {
            id: theme
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (selectorWallpapers.count === 0)
                return;

            wallpaperList.currentIndex = (wallpaperList.currentIndex + offset
                + selectorWallpapers.count) % selectorWallpapers.count;
            wallpaperList.positionViewAtIndex(wallpaperList.currentIndex, ListView.Center);
        }

        function focusCurrentWallpaper() {
            const currentPath = root.wallpapers.pathFor(selector.monitorDescription);

            if (currentPath === "" || selectorWallpapers.count === 0)
                return;

            for (let index = 0; index < selectorWallpapers.count; index++) {
                const path = selector.wallpaperFolder + "/"
                    + selectorWallpapers.get(index, "fileName");

                if (path === currentPath) {
                    wallpaperList.currentIndex = index;
                    wallpaperList.positionViewAtIndex(index, ListView.Center);
                    return;
                }
            }
        }

        function applyCurrent() {
            if (!wallpaperList.currentItem)
                return;

            root.wallpapers.setWallpaper(
                selector.monitorDescription, wallpaperList.currentItem.wallpaperPath);
            selector.close();
        }

        onVisibleChanged: {
            if (visible)
                focusCurrentWallpaper();
        }

        Connections {
            target: selectorWallpapers

            function onCountChanged() {
                if (selector.visible)
                    selector.focusCurrentWallpaper();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#b01e1e2e"

            TapHandler {
                onTapped: selector.close()
            }
        }

        Item {
            anchors.fill: parent
            focus: selector.visible

            Keys.onEscapePressed: selector.close()
            Keys.onLeftPressed: selector.selectRelative(-1)
            Keys.onRightPressed: selector.selectRelative(1)
            Keys.onReturnPressed: selector.applyCurrent()
            Keys.onEnterPressed: selector.applyCurrent()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_H) {
                    selector.selectRelative(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    selector.selectRelative(1);
                    event.accepted = true;
                }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "WALLPAPERS · " + selector.monitorDescription
                color: theme.text
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize + 4
                font.bold: true
            }

            Item {
                width: parent.width
                height: selector.portrait ? 440 : 340

                ListView {
                    id: wallpaperList

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    orientation: ListView.Horizontal
                    spacing: 18
                    clip: true
                    model: selectorWallpapers
                    snapMode: ListView.SnapOneItem
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: 240
                    preferredHighlightBegin: (width - (selector.portrait ? 260 : 480)) / 2
                    preferredHighlightEnd: preferredHighlightBegin + (selector.portrait ? 260 : 480)

                    Behavior on contentX {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Rectangle {
                        id: wallpaperTile

                        required property string fileName
                        readonly property string wallpaperPath: selector.wallpaperFolder + "/" + fileName
                        readonly property bool selected: ListView.isCurrentItem

                        width: selector.portrait ? 260 : 480
                        height: selector.portrait ? 400 : 270
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 0
                        color: theme.backgroundSecondary
                        border.color: selected ? theme.accent : theme.border
                        border.width: selected ? 3 : 1
                        opacity: selected ? 1 : 0.48
                        scale: selected ? 1.14 : 0.84

                        Behavior on opacity { NumberAnimation { duration: 180 } }
                        Behavior on x {
                            NumberAnimation {
                                duration: 240
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: Math.max(0, parent.radius - 3)
                            clip: true
                            color: "transparent"

                            Image {
                                anchors.fill: parent
                                source: "file://" + wallpaperTile.wallpaperPath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 36
                            radius: parent.radius
                            color: "#b0000000"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: wallpaperTile.fileName
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }
                        }

                        TapHandler {
                            onTapped: {
                                wallpaperList.currentIndex = index;
                                wallpaperList.positionViewAtIndex(index, ListView.Center);
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: selectorWallpapers.count === 0
                text: "No wallpapers found in the configured "
                    + (selector.portrait ? "vertical" : "horizontal") + " folder."
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: selectorWallpapers.count > 0
                text: (wallpaperList.currentIndex + 1) + " / " + selectorWallpapers.count
                    + " · Press Enter to apply"
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }
        }

    }
}
