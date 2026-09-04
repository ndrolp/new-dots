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
    required property var bookmarks
    property bool open: false

    signal closeRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: searchPanel

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property string searchQuery: ""
        readonly property var filteredBookmarks: root.bookmarks.items.filter(bookmark =>
            (bookmark.label + " " + bookmark.url).toLowerCase()
                .includes(searchQuery.trim().toLowerCase()))
        readonly property int visibleRows: filteredBookmarks.length === 0 ? 0
            : Math.min(3, Math.ceil(filteredBookmarks.length / 5))
        readonly property var searchEngines: root.bookmarks.searchEngines
        property int selectedSearchEngineIndex: root.bookmarks.activeSearchEngineIndex
        readonly property var selectedSearchEngine: searchEngines.length > 0
            ? searchEngines[Math.max(0, Math.min(selectedSearchEngineIndex,
                searchEngines.length - 1))]
            : ({ label: "Google", searchUrl: "https://www.google.com/search?q=%s",
                glyph: "󰖟" })

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-quick-search"
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
            id: browser
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (filteredBookmarks.length === 0)
                return;

            bookmarkGrid.currentIndex = (bookmarkGrid.currentIndex + offset
                + filteredBookmarks.length) % filteredBookmarks.length;
        }

        function selectSearchEngine(offset) {
            if (searchEngines.length === 0)
                return;

            selectedSearchEngineIndex = (selectedSearchEngineIndex + offset
                + searchEngines.length) % searchEngines.length;
            root.bookmarks.activeSearchEngineIndex = selectedSearchEngineIndex;
        }

        function searchUrlFor(query) {
            const template = selectedSearchEngine.searchUrl
                ? selectedSearchEngine.searchUrl.trim()
                : "https://www.google.com/search?q=%s";
            const encodedQuery = encodeURIComponent(query);

            if (template.includes("%s"))
                return template.split("%s").join(encodedQuery);
            if (template.includes("{query}"))
                return template.split("{query}").join(encodedQuery);

            return template + (template.includes("?") ? "&q=" : "?q=") + encodedQuery;
        }

        function openCurrent() {
            const query = searchQuery.trim();
            const url = filteredBookmarks.length === 0 && query !== ""
                ? searchUrlFor(query)
                : bookmarkGrid.currentItem ? bookmarkGrid.currentItem.bookmark.url : "";

            if (url === "")
                return;

            browser.command = [
                "sh", "-c",
                "xdg-open \"$1\" >/dev/null 2>&1 &",
                "quick-search-browser", url
            ];
            browser.running = true;
            close();
        }

        onVisibleChanged: {
            if (visible) {
                searchQuery = "";
                bookmarkGrid.currentIndex = 0;
                selectedSearchEngineIndex = Math.max(0, Math.min(
                    root.bookmarks.activeSearchEngineIndex, searchEngines.length - 1));
                searchInput.forceActiveFocus();
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: searchPanel.close()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width - 64, 700)
            height: 32 + searchInput.height + 10 + bookmarkGrid.cellHeight * searchPanel.visibleRows
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
            border.color: theme.border
            border.width: 1

            Behavior on height {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                TextField {
                    id: searchInput

                    width: parent.width
                    height: 46
                    placeholderText: "Search bookmarks or "
                        + searchPanel.selectedSearchEngine.label
                    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 1
                    font.bold: true
                    leftPadding: 42
                    rightPadding: 142
                    text: searchPanel.searchQuery

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
                        text: "󰍉"
                        color: theme.textMuted
                        font.pixelSize: 19
                    }

                    Rectangle {
                        id: engineSelector

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 126
                        height: 30
                        radius: root.appearance.radius
                        color: engineSelectorHover.hovered ? theme.surfaceHover
                            : Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.7)

                        HoverHandler {
                            id: engineSelectorHover
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: searchPanel.selectedSearchEngine.glyph
                                color: theme.accent
                                font.family: theme.fontFamily
                                font.pixelSize: 15
                            }

                            Text {
                                width: parent.width - 31
                                anchors.verticalCenter: parent.verticalCenter
                                text: searchPanel.selectedSearchEngine.label
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: root.appearance.textSize - 2
                                font.bold: true
                            }
                        }

                        TapHandler {
                            onTapped: searchPanel.selectSearchEngine(1)
                        }
                    }

                    onTextEdited: {
                        searchPanel.searchQuery = text;
                        bookmarkGrid.currentIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (!(event.modifiers & Qt.ControlModifier))
                            return;

                        if (event.key === Qt.Key_Left) {
                            searchPanel.selectSearchEngine(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            searchPanel.selectSearchEngine(1);
                            event.accepted = true;
                        }
                    }

                    Keys.onEscapePressed: searchPanel.close()
                    Keys.onLeftPressed: event => {
                        if (!(event.modifiers & Qt.ControlModifier))
                            searchPanel.selectRelative(-1);
                    }
                    Keys.onRightPressed: event => {
                        if (!(event.modifiers & Qt.ControlModifier))
                            searchPanel.selectRelative(1);
                    }
                    Keys.onReturnPressed: searchPanel.openCurrent()
                    Keys.onEnterPressed: searchPanel.openCurrent()
                }

                GridView {
                    id: bookmarkGrid

                    width: parent.width
                    height: parent.height - searchInput.height - parent.spacing
                    cellWidth: width / 5
                    cellHeight: cellWidth
                    model: searchPanel.filteredBookmarks
                    currentIndex: 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: searchPanel.filteredBookmarks.length > 0

                    add: Transition {
                        NumberAnimation {
                            properties: "opacity,scale"
                            from: 0
                            to: 1
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    remove: Transition {
                        NumberAnimation {
                            properties: "opacity,scale"
                            to: 0
                            duration: 120
                            easing.type: Easing.InCubic
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            properties: "x,y"
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }

                    delegate: Rectangle {
                        id: bookmarkTile

                        required property var modelData
                        readonly property var bookmark: modelData
                        readonly property bool selected: GridView.isCurrentItem

                        width: bookmarkGrid.cellWidth - 8
                        height: bookmarkGrid.cellWidth - 8
                        radius: root.appearance.radius
                        color: selected || tileHover.hovered ? theme.surfaceHover : "transparent"

                        HoverHandler {
                            id: tileHover
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 32
                            text: bookmarkTile.bookmark.glyph
                            color: theme.accent
                            font.family: theme.fontFamily
                            font.pixelSize: 38
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            anchors.topMargin: 88
                            horizontalAlignment: Text.AlignHCenter
                            text: bookmarkTile.bookmark.label
                            color: theme.text
                            elide: Text.ElideRight
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                bookmarkGrid.currentIndex = index;
                                searchPanel.openCurrent();
                            }
                        }
                    }
                }
            }
        }
    }
}
