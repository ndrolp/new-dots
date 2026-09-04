import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var clipboardHistory
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
        property string searchQuery: ""
        property int previewEntryId: -1
        property string previewSource: ""
        property bool clearArmed: false
        readonly property string previewPath: "/home/ndrolp/.cache/ndro-shell/clipboard-preview.png"
        readonly property var filteredEntries: root.clipboardHistory.orderedEntries.filter(entry =>
            entry.preview.toLowerCase().includes(searchQuery.trim().toLowerCase()))

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-clipboard-selector"
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
            id: clipboardApply
        }

        Process {
            id: imagePreview

            onExited: (exitCode, exitStatus) => {
                const currentEntry = historyList.currentItem
                    ? historyList.currentItem.entry : null;

                if (exitCode === 0 && currentEntry && currentEntry.image
                        && selector.previewEntryId === currentEntry.id)
                    selector.previewSource = "file://" + selector.previewPath;
                else
                    selector.previewSource = "";
            }
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (filteredEntries.length === 0)
                return;

            historyList.currentIndex = (historyList.currentIndex + offset
                + filteredEntries.length) % filteredEntries.length;
            historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain);
        }

        function copyCurrent() {
            if (!historyList.currentItem)
                return;

            clipboardApply.command = ["sh", "-c",
                "cliphist decode \"$1\" | wl-copy", "cliphist",
                String(historyList.currentItem.entry.id)];
            clipboardApply.running = true;
            close();
        }

        function toggleCurrentPin() {
            if (historyList.currentItem)
                root.clipboardHistory.togglePinned(historyList.currentItem.entry.id);
        }

        function deleteCurrent() {
            if (!historyList.currentItem || root.clipboardHistory.busy)
                return;

            const deletedId = historyList.currentItem.entry.id;
            root.clipboardHistory.deleteEntry(deletedId);
            previewEntryId = -1;
            previewSource = "";
            historyList.currentIndex = Math.min(historyList.currentIndex,
                Math.max(0, filteredEntries.length - 2));
        }

        function requestClearNonPinned() {
            if (root.clipboardHistory.busy)
                return;

            if (clearArmed) {
                clearConfirmTimer.stop();
                clearArmed = false;
                root.clipboardHistory.clearNonPinned();
                previewEntryId = -1;
                previewSource = "";
                historyList.currentIndex = 0;
                return;
            }

            clearArmed = true;
            clearConfirmTimer.restart();
        }

        function updatePreview() {
            const entry = historyList.currentItem ? historyList.currentItem.entry : null;

            if (!entry || !entry.image) {
                previewEntryId = -1;
                previewSource = "";
                return;
            }

            previewEntryId = entry.id;
            previewSource = "";
            imagePreview.command = ["sh", "-c",
                "mkdir -p \"$(dirname \"$2\")\" && cliphist decode \"$1\" > \"$2\"",
                "cliphist",
                String(entry.id), previewPath];
            imagePreview.running = true;
        }

        onVisibleChanged: {
            if (visible) {
                searchQuery = "";
                clearArmed = false;
                historyList.currentIndex = 0;
                previewSource = "";
                root.clipboardHistory.refresh();
                searchInput.forceActiveFocus();
            }
        }

        Timer {
            id: clearConfirmTimer

            interval: 2500
            onTriggered: selector.clearArmed = false
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: selector.close()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 660)
            height: Math.min(parent.height - 80, 520)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
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
                    placeholderText: "Search clipboard history"
                    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 1
                    font.bold: true
                    leftPadding: 42
                    text: selector.searchQuery

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
                        text: "󰆏"
                        color: theme.textMuted
                        font.pixelSize: 19
                    }

                    onTextEdited: {
                        selector.searchQuery = text;
                        historyList.currentIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            selector.close();
                        } else if (event.key === Qt.Key_Down) {
                            selector.selectRelative(1);
                        } else if (event.key === Qt.Key_Up) {
                            selector.selectRelative(-1);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            selector.copyCurrent();
                        } else if (event.key === Qt.Key_Space) {
                            selector.toggleCurrentPin();
                        } else if (event.key === Qt.Key_Delete
                                && (event.modifiers & Qt.ControlModifier)) {
                            selector.requestClearNonPinned();
                        } else if (event.key === Qt.Key_Delete) {
                            selector.deleteCurrent();
                        } else {
                            return;
                        }

                        event.accepted = true;
                    }
                }

                Row {
                    width: parent.width
                    height: 24
                    spacing: 12

                    Text {
                        width: parent.width - clearHistoryButton.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SPACE pin  •  DELETE remove  •  CTRL+DELETE clear unpinned"
                        color: theme.textMuted
                        elide: Text.ElideRight
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 3
                    }

                    Rectangle {
                        id: clearHistoryButton

                        width: 126
                        height: parent.height
                        radius: root.appearance.radius
                        color: clearHistoryHover.hovered ? theme.surfaceHover : "transparent"
                        opacity: root.clipboardHistory.busy ? 0.45 : 1

                        HoverHandler {
                            id: clearHistoryHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: selector.clearArmed ? "CONFIRM CLEAR" : "CLEAR UNPINNED"
                            color: selector.clearArmed ? theme.red : theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 3
                            font.bold: true
                        }

                        TapHandler {
                            enabled: !root.clipboardHistory.busy
                            onTapped: selector.requestClearNonPinned()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: selector.previewSource !== "" ? 138 : 0
                    visible: height > 0
                    radius: root.appearance.radius
                    color: theme.backgroundSecondary
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: selector.previewSource
                        cache: false
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                }

                ListView {
                    id: historyList

                    width: parent.width
                    height: parent.height - searchInput.height - 24 - parent.spacing * 3
                        - (selector.previewSource !== "" ? 138 : 0)
                    clip: true
                    spacing: 6
                    model: selector.filteredEntries
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    onCurrentIndexChanged: selector.updatePreview()

                    delegate: Rectangle {
                        id: historyEntry

                        required property var modelData
                        readonly property var entry: modelData
                        readonly property bool selected: ListView.isCurrentItem

                        width: historyList.width
                        height: 58
                        radius: root.appearance.radius
                        color: selected || entryHover.hovered ? theme.surfaceHover : "transparent"

                        HoverHandler {
                            id: entryHover
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: historyEntry.entry.image ? "󰋩" : "󰆏"
                            color: historyEntry.entry.image ? theme.accent : theme.textMuted
                            font.pixelSize: 19
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 46
                            anchors.right: parent.right
                            anchors.rightMargin: 82
                            anchors.verticalCenter: parent.verticalCenter
                            text: historyEntry.entry.preview
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Rectangle {
                                width: 30
                                height: 30
                                radius: root.appearance.radius
                                color: pinHover.hovered ? theme.surface : "transparent"

                                HoverHandler {
                                    id: pinHover
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐃"
                                    color: root.clipboardHistory.isPinned(historyEntry.entry.id)
                                        ? theme.accent : theme.textMuted
                                    font.family: theme.fontFamily
                                    font.pixelSize: 16
                                }

                                TapHandler {
                                    onTapped: {
                                        historyList.currentIndex = index;
                                        root.clipboardHistory.togglePinned(historyEntry.entry.id);
                                    }
                                }
                            }

                            Rectangle {
                                width: 30
                                height: 30
                                radius: root.appearance.radius
                                color: deleteHover.hovered ? theme.surface : "transparent"
                                opacity: root.clipboardHistory.busy ? 0.45 : 1

                                HoverHandler {
                                    id: deleteHover
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: theme.red
                                    font.family: theme.fontFamily
                                    font.pixelSize: 16
                                }

                                TapHandler {
                                    enabled: !root.clipboardHistory.busy
                                    onTapped: {
                                        historyList.currentIndex = index;
                                        selector.deleteCurrent();
                                    }
                                }
                            }
                        }

                        TapHandler {
                            onTapped: eventPoint => {
                                if (eventPoint.position.x >= historyEntry.width - 72)
                                    return;

                                historyList.currentIndex = index;
                                selector.copyCurrent();
                            }
                        }
                    }
                }
            }
        }
    }
}
