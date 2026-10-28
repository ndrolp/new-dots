import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "KeybindCheatsheet.js" as KeybindCheatsheet

// The keybind cheatsheet: every key binding with its description, grouped by
// modifier. It reads `hyprctl binds -j` each time it opens, so it always shows
// the bindings Hyprland has right now.
Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: cheatsheet

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property string searchQuery: ""
        property var groups: []
        readonly property var rows: KeybindCheatsheet.filter(groups, searchQuery)
            .flatMap(group => group.entries.map(entry => ({
                modifiers: group.modifiers,
                keys: entry.keys,
                description: entry.description
            })))

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-keybind-cheatsheet"
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

        Process {
            id: bindsQuery

            command: ["hyprctl", "binds", "-j"]
            stdout: StdioCollector {
                onStreamFinished: cheatsheet.groups = KeybindCheatsheet.fromOutput(text)
            }
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (rows.length === 0)
                return;

            bindingList.currentIndex = Math.max(0, Math.min(rows.length - 1,
                bindingList.currentIndex + offset));
            bindingList.positionViewAtIndex(bindingList.currentIndex, ListView.Contain);
        }

        onVisibleChanged: {
            if (!visible)
                return;

            searchQuery = "";
            bindingList.currentIndex = 0;
            bindsQuery.running = true;
            searchInput.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: cheatsheet.close()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 740)
            height: Math.min(parent.height - 80, 610)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.88)
            border.color: theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                TextField {
                    id: searchInput

                    width: parent.width
                    height: 46
                    placeholderText: "Search key bindings by key or description"
                    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 1
                    font.bold: true
                    leftPadding: 42
                    selectByMouse: true
                    text: cheatsheet.searchQuery

                    background: Rectangle {
                        radius: root.appearance.radius
                        color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g,
                            theme.backgroundSecondary.b, 0.7)
                        border.color: searchInput.activeFocus ? theme.accent : "transparent"
                        border.width: 1
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌌"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: 19
                    }

                    onTextEdited: {
                        cheatsheet.searchQuery = text;
                        bindingList.currentIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape)
                            cheatsheet.close();
                        else if (event.key === Qt.Key_Down)
                            cheatsheet.selectRelative(1);
                        else if (event.key === Qt.Key_Up)
                            cheatsheet.selectRelative(-1);
                        else if (event.key === Qt.Key_PageDown)
                            cheatsheet.selectRelative(10);
                        else if (event.key === Qt.Key_PageUp)
                            cheatsheet.selectRelative(-10);
                        else
                            return;

                        event.accepted = true;
                    }
                }

                ListView {
                    id: bindingList

                    width: parent.width
                    height: parent.height - searchInput.height - parent.spacing
                    clip: true
                    spacing: 2
                    model: cheatsheet.rows
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: bindingDelegate

                        required property var modelData
                        required property int index
                        readonly property bool groupStart: index === 0
                            || modelData.modifiers !== cheatsheet.rows[index - 1].modifiers

                        width: bindingList.width
                        height: (groupStart ? 28 : 0) + 34

                        Text {
                            visible: bindingDelegate.groupStart
                            anchors.left: parent.left
                            anchors.bottom: bindingRow.top
                            anchors.bottomMargin: 6
                            text: bindingDelegate.modelData.modifiers
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 4
                            font.bold: true
                        }

                        Rectangle {
                            id: bindingRow

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 34
                            radius: root.appearance.radius
                            color: bindingDelegate.ListView.isCurrentItem
                                ? theme.surfaceHover : "transparent"

                            Text {
                                id: keysText

                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.4
                                text: bindingDelegate.modelData.keys
                                color: theme.accent
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize - 1
                                font.bold: true
                            }

                            Text {
                                anchors.left: keysText.right
                                anchors.leftMargin: 12
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: bindingDelegate.modelData.description
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize - 1
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: bindingList.count === 0
                        text: bindsQuery.running ? "Reading key bindings…" : "No matching key bindings"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize
                    }
                }
            }
        }
    }
}
