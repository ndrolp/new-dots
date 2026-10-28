import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import "../../config" as Config
import "../../config/WallpaperModel.js" as WallpaperModel

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
        readonly property string monitorDescription: monitor ? monitor.description : ""
        readonly property bool portrait: monitor ? root.wallpapers.isPortraitMonitor(monitor) : false
        readonly property string wallpaperFolder: portrait
            ? root.wallpapers.verticalFolder : root.wallpapers.horizontalFolder
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor
            && monitor && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property real aspectRatio: height > 0 ? width / height : 16 / 9
        property real wheelDelta: 0

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

        readonly property real thumbnailHeight: 120
        readonly property int thumbnailDecodeHeight: Math.ceil(thumbnailHeight * modelData.devicePixelRatio)

        // A wallpaper at full size, with the thumbnail decode underneath so a
        // large file shows at once and sharpens when it finishes loading.
        component HeroLayer: Item {
            property string path: ""
            property int previewHeight: 0
            readonly property bool failed: full.status === Image.Error

            width: parent.width
            height: parent.height

            Image {
                anchors.fill: parent
                visible: full.status !== Image.Ready
                source: parent.path === "" ? "" : "file://" + parent.path
                sourceSize.height: parent.previewHeight
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Image {
                id: full

                anchors.fill: parent
                source: parent.path === "" ? "" : "file://" + parent.path
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
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

        function pathAt(index) {
            return selector.wallpaperFolder + "/" + selectorWallpapers.get(index, "fileName");
        }

        // `direction` is the side the hero slides in from: 1 for the right,
        // -1 for the left, 0 for no slide.
        function select(index, direction) {
            if (selectorWallpapers.count === 0)
                return;

            filmstrip.currentIndex = index;
            hero.show(pathAt(index), direction);
        }

        function selectRelative(offset) {
            select(WallpaperModel.step(filmstrip.currentIndex, offset, selectorWallpapers.count),
                offset);
        }

        function focusCurrentWallpaper() {
            const currentPath = root.wallpapers.pathFor(selector.monitorDescription);

            for (let index = 0; index < selectorWallpapers.count; index++) {
                if (pathAt(index) === currentPath) {
                    select(index, 0);
                    return;
                }
            }

            select(0, 0);
        }

        function applyCurrent() {
            if (selectorWallpapers.count === 0)
                return;

            root.wallpapers.setWallpaper(selector.monitorDescription, pathAt(filmstrip.currentIndex));
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

        MouseArea {
            anchors.fill: parent
            focus: selector.visible

            onClicked: selector.close()
            onWheel: wheel => {
                selector.wheelDelta += wheel.angleDelta.y;

                while (Math.abs(selector.wheelDelta) >= 120) {
                    const offset = selector.wheelDelta > 0 ? -1 : 1;
                    selector.wheelDelta += offset * 120;
                    selector.selectRelative(offset);
                }
            }

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

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.55)
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "WALLPAPERS · " + (selector.monitor ? selector.monitor.name : "")
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 4
                    font.bold: true
                }

                Rectangle {
                    id: hero

                    property string shownPath: ""
                    property string leavingPath: ""
                    property int direction: 0

                    function show(path, slideFrom) {
                        if (path === shownPath)
                            return;

                        slide.stop();
                        leavingPath = shownPath;
                        shownPath = path;
                        direction = slideFrom;

                        if (leavingPath === "" || slideFrom === 0) {
                            leavingPath = "";
                            incoming.x = 0;
                            return;
                        }

                        slide.start();
                    }

                    anchors.horizontalCenter: parent.horizontalCenter
                    height: selector.height * (selector.portrait ? 0.5 : 0.6)
                    width: height * selector.aspectRatio
                    visible: selectorWallpapers.count > 0
                    radius: theme.radius
                    color: theme.backgroundSecondary
                    border.color: theme.accent
                    border.width: 3

                    Item {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        clip: true

                        HeroLayer {
                            id: leaving

                            path: hero.leavingPath
                            previewHeight: selector.thumbnailDecodeHeight
                            visible: hero.leavingPath !== ""
                        }

                        HeroLayer {
                            id: incoming

                            path: hero.shownPath
                            previewHeight: selector.thumbnailDecodeHeight
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: incoming.failed
                            text: "Preview unavailable"
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }
                    }

                    ParallelAnimation {
                        id: slide

                        NumberAnimation {
                            target: incoming
                            property: "x"
                            from: hero.direction * incoming.width
                            to: 0
                            duration: root.appearance.motion.long
                            easing.type: root.appearance.motion.easing
                        }

                        NumberAnimation {
                            target: leaving
                            property: "x"
                            from: 0
                            to: -hero.direction * leaving.width
                            duration: root.appearance.motion.long
                            easing.type: root.appearance.motion.easing
                        }

                        onFinished: {
                            hero.leavingPath = "";
                            leaving.x = 0;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selector.applyCurrent()
                    }
                }

                ListView {
                    id: filmstrip

                    readonly property real thumbnailWidth: selector.thumbnailHeight * selector.aspectRatio

                    width: parent.width
                    height: selector.thumbnailHeight + 8
                    orientation: ListView.Horizontal
                    spacing: 10
                    interactive: false
                    model: selectorWallpapers
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: root.appearance.motion.long
                    preferredHighlightBegin: (width - thumbnailWidth) / 2
                    preferredHighlightEnd: preferredHighlightBegin + thumbnailWidth

                    delegate: Rectangle {
                        id: thumbnail

                        required property string fileName
                        required property int index
                        readonly property bool selected: ListView.isCurrentItem

                        y: 4
                        width: filmstrip.thumbnailWidth
                        height: selector.thumbnailHeight
                        radius: theme.radius
                        color: theme.backgroundSecondary
                        border.color: selected ? theme.accent : theme.border
                        border.width: selected ? 3 : 1
                        opacity: selected ? 1 : 0.55

                        Behavior on opacity { NumberAnimation { duration: root.appearance.motion.medium } }
                        Behavior on border.color { ColorAnimation { duration: root.appearance.motion.medium } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: parent.border.width
                            radius: Math.max(0, parent.radius - parent.border.width)
                            clip: true
                            color: "transparent"

                            Image {
                                anchors.fill: parent
                                source: "file://" + selector.wallpaperFolder + "/" + thumbnail.fileName
                                sourceSize.height: selector.thumbnailDecodeHeight
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selector.select(thumbnail.index,
                                Math.sign(thumbnail.index - filmstrip.currentIndex))
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
                    width: Math.min(implicitWidth, parent.width - 32)
                    visible: selectorWallpapers.count > 0
                    text: selectorWallpapers.get(filmstrip.currentIndex, "fileName")
                        + "  ·  " + (filmstrip.currentIndex + 1) + " / " + selectorWallpapers.count
                    color: theme.textMuted
                    elide: Text.ElideMiddle
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize - 1
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "h/l  ·  Enter apply  ·  Esc close"
                    color: theme.textDisabled
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize - 2
                }
            }
        }
    }
}
