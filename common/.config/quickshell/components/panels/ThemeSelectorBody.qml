import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "../../config/ColorschemeColors.js" as ColorschemeColors
import "ColorschemePreview.js" as ColorschemePreview

// The colorscheme selector: the colorschemes, each one a colorscheme preview
// as it is selected (H/L, J/K or the arrows), applied with Enter. Closing it
// any other way shows the active colorscheme again. Shown full-screen
// (ThemeSelector.qml) or inside a capsule (ThemeSelectorPopup.qml); `active`
// is true while it is shown.
Item {
    id: root

    required property var appearance
    // The wallpapers (config/Wallpapers.qml), for each colorscheme's own; null
    // shows none.
    property var wallpapers: null
    property var firstWallpaper: null
    property var secondWallpaper: null
    // Shown: becoming true lists the colorschemes and selects the active one.
    property bool active: false

    // The repo's colorschemes folder. The shell's folder is common/.config/quickshell in the repo (stow
    // links ~/.config/quickshell to it), and the system resolves ".." through that link.
    readonly property string colorschemes: Quickshell.shellPath("../../../colorschemes")
    readonly property string changer: colorschemes + "/colorscheme_changer.sh"
    property string activeTheme: ""
    property string previewTheme: ""
    property var preview: ColorschemePreview.idle
    property bool applyingTheme: false
    // The colorschemes the changer is listing, and whether the list is being replaced (moving the
    // selection then is not a choice to preview).
    property var listedThemes: []
    property bool refreshingList: false

    signal closeRequested()

    implicitHeight: content.implicitHeight

    // The colorschemes, listed by the changer each time the selector opens, so a new colorscheme
    // folder shows without reloading the shell: the colorschemes folder also holds the active and
    // shown links, which are not colorschemes.
    ListModel {
        id: themes
    }

    Config.Theme {
        id: theme
    }

    function close() {
        root.closeRequested();
    }

    function previewSelectedTheme(themeName) {
        runPreview(ColorschemePreview.requested(preview, themeName));
    }

    function runPreview(step) {
        preview = step.state;
        if (step.start === "")
            return;

        themePreview.command = [
            root.changer,
            "--preview", step.start
        ];
        themePreview.running = true;
    }

    function previewCurrent() {
        if (themeList.currentItem)
            previewSelectedTheme(themeList.currentItem.themeName);
    }

    function refreshThemes() {
        if (themeListing.running)
            return;

        listedThemes = [];
        themeListing.running = true;
    }

    // showListedThemes: replaces the list with the one the changer gave, when it differs.
    function showListedThemes() {
        let same = listedThemes.length === themes.count;
        for (let index = 0; same && index < themes.count; index++)
            same = themes.get(index).fileName === listedThemes[index];
        if (same)
            return;

        refreshingList = true;
        themes.clear();
        for (const name of listedThemes)
            themes.append({ fileName: name });
        refreshingList = false;
    }

    function loadActiveTheme() {
        if (!themeState.running)
            themeState.running = true;
    }

    function selectRelative(offset) {
        if (themes.count === 0)
            return;

        themeList.currentIndex = (themeList.currentIndex + offset + themes.count) % themes.count;
            }

    function applyCurrent() {
        if (!themeList.currentItem || themeApply.running)
            return;

        applyingTheme = true;
        themeApply.command = [
            root.changer,
            themeList.currentItem.themeName
        ];
        themeApply.running = true;
        close();
    }

    Process {
        id: themeApply
    }

    Process {
        id: themePreview

        onExited: root.runPreview(ColorschemePreview.exited(root.preview))
    }

    Process {
        id: themeListing

        command: [root.changer, "--list"]

        stdout: SplitParser {
            onRead: data => {
                if (data.trim() !== "")
                    root.listedThemes.push(data.trim());
            }
        }

        onExited: {
            root.showListedThemes();
            if (root.active)
                root.loadActiveTheme();
        }
    }

    // The active colorscheme is the machine-local link colorschemes/active; the changer reads it
    // (and creates it from the default colorscheme when it is missing).
    Process {
        id: themeState

        command: [root.changer, "--active"]

        stdout: SplitParser {
            onRead: data => {
                root.activeTheme = data.trim();
                root.preview = ColorschemePreview.shown(root.preview, root.activeTheme).state;

                for (let index = 0; index < themes.count; index++) {
                    if (themes.get(index).fileName === root.activeTheme) {
                        themeList.currentIndex = index;
                        themeList.positionViewAtIndex(index, ListView.Center);
                        break;
                    }
                }
            }
        }
    }

    // Opening lists the colorschemes again; closing without applying, however it
    // closes, shows the active colorscheme again.
    onActiveChanged: {
        if (active) {
            applyingTheme = false;
            refreshThemes();
            keys.forceActiveFocus();
        } else if (!applyingTheme && activeTheme !== "") {
            previewSelectedTheme(activeTheme);
        }
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: root.active

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selectRelative(-1)
        Keys.onRightPressed: root.selectRelative(1)
        Keys.onUpPressed: root.selectRelative(-1)
        Keys.onDownPressed: root.selectRelative(1)
        Keys.onReturnPressed: root.applyCurrent()
        Keys.onEnterPressed: root.applyCurrent()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H) {
                root.selectRelative(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_J) {
                root.selectRelative(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                root.selectRelative(-1);
                event.accepted = true;
            }
        }
    }

    // The selected colorscheme's wallpaper: the first of its horizontal ones,
    // or "" without colorscheme wallpapers (Config.Wallpapers.colorschemesFolder).
    readonly property string colorschemesFolder: wallpapers
        ? String(wallpapers.colorschemesFolder).replace(/\/+$/, "") : ""
    readonly property string selectedTheme: themeList.currentItem ? themeList.currentItem.themeName : ""
    readonly property string selectedWallpaper: selectedWallpapers.pathAt(0)

    Config.WallpaperFiles {
        id: selectedWallpapers

        // Only while shown: every bar has a selector.
        path: root.active && root.colorschemesFolder !== "" && root.selectedTheme !== ""
            ? root.colorschemesFolder + "/" + root.selectedTheme + "/Horizontal" : ""
    }

    // Two layers crossfade: the next wallpaper loads into the hidden one and
    // fades in once it is ready.
    property bool frontIsFirst: true

    onSelectedWallpaperChanged: {
        const back = frontIsFirst ? secondWallpaper : firstWallpaper;
        if (!back)
            return;
        back.source = selectedWallpaper === "" ? "" : "file://" + selectedWallpaper;
        if (selectedWallpaper === "" || back.status === Image.Ready)
            frontIsFirst = !frontIsFirst;
    }

    Column {
        id: content

        width: parent.width
        spacing: 10

        ShellText {
            text: "THEMES"
            color: theme.text
            font.family: theme.fontFamily
            font.pixelSize: 15
            font.bold: true
        }

        // The slider on the left, over the selected colorscheme's wallpaper
        // fading into the dark towards it.
        Item {
            id: stage

            width: parent.width
            height: themeList.rowHeight * 5 + themeList.spacing * 4

            Rectangle {
                id: stageBackground

                anchors.fill: parent
                radius: 10
                color: theme.backgroundSecondary
            }

            Item {
                id: wallpaperLayers

                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: stageMask
                }

                Repeater {
                    model: 2

                    delegate: Image {
                        id: wallpaperLayer

                        required property int index
                        readonly property bool front: (index === 0) === root.frontIsFirst

                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: parent.width * 0.62
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.height: Math.ceil(height * 1.5)
                        opacity: front && status === Image.Ready ? 1 : 0

                        Component.onCompleted: {
                            if (index === 0)
                                root.firstWallpaper = wallpaperLayer;
                            else
                                root.secondWallpaper = wallpaperLayer;
                        }

                        onStatusChanged: {
                            if (status === Image.Ready && !front
                                    && source.toString() === "file://" + root.selectedWallpaper)
                                root.frontIsFirst = index === 0;
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.appearance.motion.medium
                                easing.type: root.appearance.motion.easing
                            }
                        }
                    }
                }

                // Into the dark: across the wallpaper's left part, and a little
                // at its top and bottom.
                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    x: parent.width * 0.38
                    width: parent.width * 0.4
                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop { position: 0; color: theme.backgroundSecondary }
                        GradientStop { position: 0.45; color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g, theme.backgroundSecondary.b, 0.75) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g, theme.backgroundSecondary.b, 0.35) }
                        GradientStop { position: 0.25; color: "transparent" }
                        GradientStop { position: 0.75; color: "transparent" }
                        GradientStop { position: 1; color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g, theme.backgroundSecondary.b, 0.55) }
                    }
                }
            }

            Rectangle {
                id: stageMask

                anchors.fill: parent
                radius: stageBackground.radius
                visible: false
                layer.enabled: true
            }

            ListView {
                id: themeList

                readonly property real rowHeight: 52

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                width: Math.min(250, parent.width * 0.46)
                spacing: 4
                clip: true
                model: themes
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (height - rowHeight) / 2
                preferredHighlightEnd: preferredHighlightBegin + rowHeight
                highlightMoveDuration: root.appearance.motion.medium
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: {
                    if (root.active && !root.refreshingList)
                        root.previewCurrent();
                }

                delegate: Rectangle {
                    id: themeTile

                    required property string fileName
                    required property int index
                    readonly property string themeName: fileName
                    readonly property bool selected: ListView.isCurrentItem
                    readonly property bool active: themeName === root.activeTheme
                    // How far from the selected one: the slider fades and
                    // shrinks the colorschemes away from it.
                    readonly property int distance: Math.abs(index - themeList.currentIndex)

                    width: themeList.width
                    height: themeList.rowHeight
                    radius: 8
                    color: selected ? Qt.rgba(theme.surfaceHover.r, theme.surfaceHover.g, theme.surfaceHover.b, 0.85)
                        : tileHover.hovered ? Qt.rgba(theme.surfaceHover.r, theme.surfaceHover.g, theme.surfaceHover.b, 0.5) : "transparent"
                    border.color: active ? theme.accent : "transparent"
                    border.width: active ? 1 : 0
                    opacity: [1, 0.6, 0.35][Math.min(distance, 2)]
                    scale: 1 - Math.min(distance, 3) * 0.05

                    property var colours: ColorschemeColors.fallback

                    FileView {
                        path: root.colorschemes + "/" + themeTile.themeName
                            + "/quickshell/colors.json"

                        onLoaded: themeTile.colours = ColorschemeColors.fromJson(text())
                    }

                    Behavior on color {
                        ColorAnimation { duration: root.appearance.motion.short }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: root.appearance.motion.medium }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: root.appearance.motion.medium
                            easing.type: root.appearance.motion.easing
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: [
                                    themeTile.colours.accent,
                                    themeTile.colours.blue,
                                    themeTile.colours.green,
                                    themeTile.colours.red
                                ]

                                delegate: Rectangle {
                                    required property color modelData

                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: modelData
                                }
                            }
                        }

                        ShellText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 94
                            text: themeTile.themeName
                            color: themeTile.colours.text
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                        }

                        ShellText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰄬"
                            visible: themeTile.active
                            color: theme.accent
                            font.pixelSize: 16
                        }
                    }

                    HoverHandler {
                        id: tileHover
                    }

                    TapHandler {
                        onTapped: themeList.currentIndex = themeTile.index
                    }
                }
            }
        }

        ShellText {
            text: themes.count > 0
                ? "󰄬 active · J / K or arrows · Enter to apply"
                : "No theme directories found"
            color: theme.textMuted
            font.family: theme.fontFamily
            font.pixelSize: 11
        }
    }
}
