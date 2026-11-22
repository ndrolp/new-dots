import Quickshell.Hyprland
import QtQuick
import "../../config" as Config
import "." as Panels

// The wallpaper picker inside a capsule: modules/WallpaperSelector.qml opens it
// here when the focused bar is one, instead of the full-screen picker. A strip
// of the monitor's wallpapers; moving through it (h/l, the arrows, the wheel,
// a click) shows each one on the monitor's desktop at once, as a preview.
// Enter, or clicking the one selected, keeps it as the monitor's wallpaper;
// closing any other way (Esc, a click outside) shows its own one again.
BarPopup {
    id: root

    // The wallpaper picker module (modules/WallpaperSelector.qml).
    required property var feature
    readonly property var wallpapers: feature.wallpapers

    readonly property var monitor: barWindow.screen ? Hyprland.monitorFor(barWindow.screen) : null
    readonly property string monitorDescription: monitor ? monitor.description : ""
    readonly property bool portrait: monitor ? wallpapers.isPortraitMonitor(monitor) : false
    readonly property string folder: portrait ? wallpapers.verticalFolder : wallpapers.horizontalFolder
    readonly property real aspectRatio: barWindow.screen && barWindow.screen.height > 0
        ? barWindow.screen.width / barWindow.screen.height : 16 / 9
    readonly property real thumbnailHeight: portrait ? 120 : 72
    readonly property real thumbnailWidth: thumbnailHeight * aspectRatio
    readonly property int thumbnailDecodeHeight: Math.ceil(thumbnailHeight
        * (barWindow.screen ? barWindow.screen.devicePixelRatio : 1))
    readonly property int thumbnailsAcross: 5
    readonly property real thumbnailSpacing: 8
    // The wallpaper shown as a preview, or "" while the monitor shows its own.
    property string previewed: ""
    property real wheelDelta: 0

    popup: "wallpapers"
    popupWidth: Math.max(320, thumbnailsAcross * thumbnailWidth
        + (thumbnailsAcross - 1) * thumbnailSpacing + 24)

    function pathAt(index) {
        return wallpaperFiles.pathAt(index);
    }

    // Selects the monitor's own wallpaper, or the first, without a preview.
    function selectOwn() {
        const own = wallpapers.pathFor(monitorDescription);
        let index = 0;
        for (let candidate = 0; candidate < wallpaperFiles.count; candidate++) {
            if (pathAt(candidate) === own) {
                index = candidate;
                break;
            }
        }
        strip.currentIndex = wallpaperFiles.count > 0 ? index : -1;
        strip.positionViewAtIndex(strip.currentIndex, ListView.Center);
    }

    // Selects a wallpaper and previews it once the selection rests a moment,
    // so holding a key doesn't start a transition per wallpaper.
    function select(index) {
        if (wallpaperFiles.count === 0)
            return;

        strip.currentIndex = (index + wallpaperFiles.count) % wallpaperFiles.count;
        previewDelay.restart();
    }

    function previewSelected() {
        if (strip.currentIndex < 0)
            return;

        const path = pathAt(strip.currentIndex);
        if (path === previewed)
            return;
        if (path === wallpapers.pathFor(monitorDescription)) {
            if (previewed !== "")
                wallpapers.restore(monitorDescription);
            previewed = "";
            return;
        }
        previewed = path;
        wallpapers.preview(monitorDescription, path);
    }

    // Keeps the selected wallpaper and closes.
    function keep() {
        if (strip.currentIndex < 0)
            return;

        previewDelay.stop();
        const path = pathAt(strip.currentIndex);
        if (path === previewed)
            wallpapers.assign(monitorDescription, path);
        else
            wallpapers.setWallpaper(monitorDescription, path);
        previewed = "";
        close();
    }

    function close() {
        popups.popupClosed(popup);
    }

    onOpenChanged: {
        if (open) {
            previewed = "";
            selectOwn();
            return;
        }
        // Closed without keeping one: the monitor's own wallpaper again.
        previewDelay.stop();
        if (previewed !== "")
            wallpapers.restore(monitorDescription);
        previewed = "";
    }

    onShownChanged: {
        if (shown)
            keys.forceActiveFocus();
    }

    Timer {
        id: previewDelay

        interval: 150
        onTriggered: root.previewSelected()
    }

    Config.WallpaperFiles {
        id: wallpaperFiles

        path: root.folder

        onCountChanged: {
            if (root.open && strip.currentIndex < 0)
                root.selectOwn();
        }
    }

    Config.Theme {
        id: theme
    }

    Item {
        id: keys

        width: parent.width
        height: content.height
        focus: true

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.select(strip.currentIndex - 1)
        Keys.onRightPressed: root.select(strip.currentIndex + 1)
        Keys.onReturnPressed: root.keep()
        Keys.onEnterPressed: root.keep()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H) {
                root.select(strip.currentIndex - 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                root.select(strip.currentIndex + 1);
                event.accepted = true;
            }
        }

        Column {
            id: content

            width: parent.width
            spacing: 8

            PopupHeader {
                appearance: root.appearance
                title: "Wallpapers"
                subtitle: root.monitor ? root.monitor.name : ""
            }

            ListView {
                id: strip

                width: parent.width
                height: root.thumbnailHeight + 8
                visible: wallpaperFiles.count > 0
                orientation: ListView.Horizontal
                spacing: root.thumbnailSpacing
                interactive: false
                clip: true
                currentIndex: -1
                model: wallpaperFiles
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: root.appearance.motion.medium
                preferredHighlightBegin: (width - root.thumbnailWidth) / 2
                preferredHighlightEnd: preferredHighlightBegin + root.thumbnailWidth

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        root.wheelDelta += event.angleDelta.y !== 0 ? event.angleDelta.y : -event.angleDelta.x;
                        while (Math.abs(root.wheelDelta) >= 120) {
                            const step = root.wheelDelta > 0 ? -1 : 1;
                            root.wheelDelta += step * 120;
                            root.select(strip.currentIndex + step);
                        }
                    }
                }

                delegate: Rectangle {
                    id: thumbnail

                    required property string filePath
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem

                    y: 4
                    width: root.thumbnailWidth
                    height: root.thumbnailHeight
                    radius: theme.radius
                    color: theme.backgroundSecondary
                    border.color: selected ? theme.accent : theme.border
                    border.width: selected ? 2 : 1
                    opacity: selected ? 1 : 0.6

                    Behavior on opacity { NumberAnimation { duration: root.appearance.motion.medium } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        radius: Math.max(0, parent.radius - parent.border.width)
                        clip: true
                        color: "transparent"

                        Panels.WallpaperThumbnail {
                            filePath: thumbnail.filePath
                            decodeHeight: root.thumbnailDecodeHeight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (thumbnail.selected)
                                root.keep();
                            else
                                root.select(thumbnail.index);
                        }
                    }
                }
            }

            Panels.ShellText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: wallpaperFiles.count === 0
                text: "No wallpapers in the " + (root.portrait ? "vertical" : "horizontal") + " folder."
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize
            }

            Panels.ShellText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: wallpaperFiles.count > 0
                text: (strip.currentIndex >= 0 ? wallpaperFiles.get(strip.currentIndex, "fileName") : "")
                    + "  ·  " + (strip.currentIndex + 1) + " / " + wallpaperFiles.count
                color: theme.textMuted
                elide: Text.ElideMiddle
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize - 1
            }

            Panels.ShellText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "h/l  ·  Enter keep  ·  Esc close"
                color: theme.textDisabled
                font.family: theme.fontFamily
                font.pixelSize: root.appearance.textSize - 2
            }
        }
    }
}
