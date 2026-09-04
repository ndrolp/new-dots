import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import "../../config" as Config

Variants {
    id: root

    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: selector

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property string activeTheme: ""
        property string previewTheme: ""
        property string requestedPreviewTheme: ""
        property bool applyingTheme: false

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-theme-selector"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        FolderListModel {
            id: themes

            folder: "file:///home/ndrolp/.dotfiles/colorschemes"
            showDirs: true
            showFiles: false
            showDotAndDotDot: false
        }

        Config.Theme {
            id: theme
        }

        function close() {
            if (!applyingTheme && activeTheme !== "")
                previewSelectedTheme(activeTheme);

            root.closeRequested();
        }

        function previewSelectedTheme(themeName) {
            if (themeName === "" || requestedPreviewTheme === themeName)
                return;

            requestedPreviewTheme = themeName;
            if (themePreview.running)
                return;

            themePreview.previewedTheme = themeName;
            themePreview.command = [
                "/home/ndrolp/.dotfiles/colorschemes/colorscheme_changer.sh",
                "--preview", themeName
            ];
            themePreview.running = true;
        }

        function previewCurrent() {
            if (themeList.currentItem)
                previewSelectedTheme(themeList.currentItem.themeName);
        }

        function loadActiveTheme() {
            if (!themeState.running)
                themeState.running = true;
        }

        function selectRelative(offset) {
            if (themes.count === 0)
                return;

            themeList.currentIndex = (themeList.currentIndex + offset + themes.count) % themes.count;
            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Center);
        }

        function applyCurrent() {
            if (!themeList.currentItem || themeApply.running)
                return;

            applyingTheme = true;
            themeApply.command = [
                "/home/ndrolp/.dotfiles/colorschemes/colorscheme_changer.sh",
                themeList.currentItem.themeName
            ];
            themeApply.running = true;
            selector.close();
        }

        Process {
            id: themeApply
        }

        Process {
            id: themePreview

            property string previewedTheme: ""

            onExited: {
                if (selector.requestedPreviewTheme !== previewedTheme)
                    selector.previewSelectedTheme(selector.requestedPreviewTheme);
            }
        }

        Process {
            id: themeState

            command: ["sh", "-c", "cat ~/.dotfiles/colorschemes/theme.txt 2>/dev/null"]

            stdout: SplitParser {
                onRead: data => {
                    selector.activeTheme = data.trim();
                    selector.requestedPreviewTheme = selector.activeTheme;

                    for (let index = 0; index < themes.count; index++) {
                        if (themes.get(index, "fileName") === selector.activeTheme) {
                            themeList.currentIndex = index;
                            themeList.positionViewAtIndex(index, ListView.Contain);
                            break;
                        }
                    }
                }
            }
        }

        onVisibleChanged: {
            if (visible) {
                applyingTheme = false;
                loadActiveTheme();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

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
            Keys.onUpPressed: selector.selectRelative(-1)
            Keys.onDownPressed: selector.selectRelative(1)
            Keys.onReturnPressed: selector.applyCurrent()
            Keys.onEnterPressed: selector.applyCurrent()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_H) {
                    selector.selectRelative(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_L || event.key === Qt.Key_J) {
                    selector.selectRelative(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_K) {
                    selector.selectRelative(-1);
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 430)
            height: content.implicitHeight + 32
            radius: 12
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.88)
            border.color: theme.border
            border.width: 1

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    text: "THEMES"
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                ListView {
                    id: themeList

                    width: parent.width
                    height: Math.min(contentHeight, 276)
                    spacing: 4
                    clip: true
                    model: themes
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height - 52

                    onCurrentIndexChanged: {
                        if (selector.visible)
                            selector.previewCurrent();
                    }

                    Behavior on contentY {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Rectangle {
                        id: themeTile

                        required property string fileName
                        readonly property string themeName: fileName
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property bool active: themeName === selector.activeTheme

                        width: themeList.width
                        height: 52
                        radius: 8
                        color: selected || tileHover.hovered ? theme.surfaceHover : "transparent"
                        border.color: active ? theme.accent : "transparent"
                        border.width: active ? 1 : 0

                        Loader {
                            id: themeDefinition

                            source: "file:///home/ndrolp/.dotfiles/colorschemes/"
                                + themeTile.themeName + "/quickshell/Theme.qml"
                        }

                        Behavior on color {
                            ColorAnimation { duration: 120 }
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
                                    model: themeDefinition.item ? [
                                        themeDefinition.item.accent,
                                        themeDefinition.item.blue,
                                        themeDefinition.item.green,
                                        themeDefinition.item.red
                                    ] : [theme.accent, theme.blue, theme.green, theme.red]

                                    delegate: Rectangle {
                                        required property color modelData

                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: modelData
                                    }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 94
                                text: themeTile.themeName
                                color: themeDefinition.item
                                    ? themeDefinition.item.text : theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
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
                            onTapped: {
                                themeList.currentIndex = index;
                                themeList.positionViewAtIndex(index, ListView.Contain);
                            }
                        }
                    }
                }

                Text {
                    text: themes.count > 0
                        ? "󰄬 active · H / L or arrows · Enter to apply"
                        : "No theme directories found"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
