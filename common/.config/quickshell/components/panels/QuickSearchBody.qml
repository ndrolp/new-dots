import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../../config" as Config
import "QuickSearchResults.js" as QuickSearchResults

// The quick search: a search field over at most two rows of bookmarks
// (QuickSearchResults.js). Typing filters them; Enter opens the selected one
// or, when none matches, searches the web with the chosen search engine
// (Ctrl+Left/Right changes it). Shown full-screen (QuickSearch.qml) or inside
// a capsule (QuickSearchPopup.qml); `active` is true while it is shown.
Item {
    id: root

    required property var appearance
    required property var bookmarks
    // Shown: becoming true starts a fresh search with the field focused.
    property bool active: false

    signal closeRequested()

    property string searchQuery: ""
    readonly property var filteredBookmarks: QuickSearchResults.shown(bookmarks.items, searchQuery)
    readonly property int rows: QuickSearchResults.rows(filteredBookmarks.length)
    readonly property var searchEngines: bookmarks.searchEngines
    property int selectedSearchEngineIndex: bookmarks.activeSearchEngineIndex
    readonly property var selectedSearchEngine: searchEngines.length > 0
        ? searchEngines[Math.max(0, Math.min(selectedSearchEngineIndex,
            searchEngines.length - 1))]
        : ({ label: "Google", searchUrl: "https://www.google.com/search?q=%s",
            glyph: "󰖟" })

    implicitHeight: content.implicitHeight

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

    onActiveChanged: {
        if (active) {
            searchQuery = "";
            bookmarkGrid.currentIndex = 0;
            selectedSearchEngineIndex = Math.max(0, Math.min(
                bookmarks.activeSearchEngineIndex, searchEngines.length - 1));
            searchInput.forceActiveFocus();
        }
    }

    Column {
        id: content

        width: parent.width
        spacing: 10

        TextField {
            id: searchInput

            width: parent.width
            height: 46
            placeholderText: "Search bookmarks or "
                + root.selectedSearchEngine.label
            placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
            color: theme.text
            font.family: theme.fontFamily
            font.pixelSize: root.appearance.textSize + 1
            font.bold: true
            leftPadding: 42
            rightPadding: 142
            text: root.searchQuery

            background: Rectangle {
                radius: root.appearance.radius
                color: Qt.rgba(theme.backgroundSecondary.r, theme.backgroundSecondary.g,
                    theme.backgroundSecondary.b, 0.7)
                border.color: searchInput.activeFocus ? theme.accent : "transparent"
                border.width: 1
            }

            ShellText {
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

                    ShellText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedSearchEngine.glyph
                        color: theme.accent
                        font.family: theme.fontFamily
                        font.pixelSize: 15
                    }

                    ShellText {
                        width: parent.width - 31
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedSearchEngine.label
                        color: theme.text
                        elide: Text.ElideRight
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 2
                        font.bold: true
                    }
                }

                TapHandler {
                    onTapped: root.selectSearchEngine(1)
                }
            }

            onTextEdited: {
                root.searchQuery = text;
                bookmarkGrid.currentIndex = 0;
            }

            Keys.onPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier))
                    return;

                if (event.key === Qt.Key_Left) {
                    root.selectSearchEngine(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    root.selectSearchEngine(1);
                    event.accepted = true;
                }
            }

            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier))
                    root.selectRelative(-1);
            }
            Keys.onRightPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier))
                    root.selectRelative(1);
            }
            Keys.onReturnPressed: root.openCurrent()
            Keys.onEnterPressed: root.openCurrent()
        }

        GridView {
            id: bookmarkGrid

            width: parent.width
            height: cellHeight * root.rows
            interactive: false
            cellWidth: width / 5
            cellHeight: cellWidth
            model: root.filteredBookmarks
            currentIndex: 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: root.filteredBookmarks.length > 0

            add: Transition {
                NumberAnimation {
                    properties: "opacity,scale"
                    from: 0
                    to: 1
                    duration: root.appearance.motion.medium
                    easing.type: root.appearance.motion.easing
                }
            }

            remove: Transition {
                NumberAnimation {
                    properties: "opacity,scale"
                    to: 0
                    duration: root.appearance.motion.short
                    easing.type: Easing.InCubic
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: root.appearance.motion.medium
                    easing.type: root.appearance.motion.easing
                }
            }

            delegate: Rectangle {
                id: bookmarkTile

                required property var modelData
                required property int index
                readonly property var bookmark: modelData
                readonly property bool selected: GridView.isCurrentItem

                width: bookmarkGrid.cellWidth - 8
                height: bookmarkGrid.cellWidth - 8
                radius: root.appearance.radius
                color: selected || tileHover.hovered ? theme.surfaceHover : "transparent"

                HoverHandler {
                    id: tileHover
                }

                ShellText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                    text: bookmarkTile.bookmark.glyph
                    color: theme.accent
                    font.family: theme.fontFamily
                    font.pixelSize: 38
                }

                ShellText {
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
                        bookmarkGrid.currentIndex = bookmarkTile.index;
                        root.openCurrent();
                    }
                }
            }
        }
    }
}
