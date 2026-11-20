import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "EmojiSearch.js" as EmojiSearch
import "SearchQuery.js" as SearchQuery

Variants {
    id: root

    required property var appearance
    required property var bookmarks
    required property var clipboardHistory
    required property var monitors
    required property var workspaceService
    property bool open: false
    // What the field holds when search opens, e.g. ":" to open on emoji.
    property string initialQuery: ""

    signal closeRequested()
    signal settingsRequested()
    signal keybindCheatsheetRequested()
    signal webAppMakerRequested()
    signal printersRequested()
    signal androidDevicesRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: searchPanel

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-unified-search"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Config.Theme {
            id: theme
        }

        function close() {
            root.closeRequested();
        }


        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: searchPanel.close()
            }
        }

        Rectangle {
            id: searchCard

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 740)
            height: Math.min(parent.height - 80, 610)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.88)
            border.color: theme.border
            border.width: 1

            UnifiedSearchBody {
                anchors.fill: parent
                anchors.margins: 16
                appearance: root.appearance
                bookmarks: root.bookmarks
                clipboardHistory: root.clipboardHistory
                monitors: root.monitors
                workspaceService: root.workspaceService
                initialQuery: root.initialQuery
                active: searchPanel.visible

                onCloseRequested: searchPanel.close()
                onSettingsRequested: root.settingsRequested()
                onKeybindCheatsheetRequested: root.keybindCheatsheetRequested()
                onWebAppMakerRequested: root.webAppMakerRequested()
                onPrintersRequested: root.printersRequested()
                onAndroidDevicesRequested: root.androidDevicesRequested()
            }
        }
    }
}
