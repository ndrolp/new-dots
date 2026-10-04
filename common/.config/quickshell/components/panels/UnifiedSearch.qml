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
    required property var clipboardHistory
    required property var monitors
    required property var workspaceService
    property bool open: false

    signal closeRequested()
    signal settingsRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: searchPanel

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        property string searchQuery: ""
        readonly property var categories: [
            "ALL", "APPLICATIONS", "BOOKMARKS", "CLIPBOARD", "WINDOWS", "ACTIONS"
        ]
        property int selectedCategoryIndex: 0
        readonly property string selectedCategory: categories[selectedCategoryIndex]
        readonly property var searchEngines: root.bookmarks.searchEngines
        property int selectedSearchEngineIndex: root.bookmarks.activeSearchEngineIndex
        readonly property var selectedSearchEngine: searchEngines.length > 0
            ? searchEngines[Math.max(0, Math.min(selectedSearchEngineIndex,
                searchEngines.length - 1))]
            : ({ label: "Google", searchUrl: "https://www.google.com/search?q=%s",
                glyph: "󰖟" })
        readonly property var results: buildResults()

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

        Process {
            id: actionProcess
        }

        function textValue(value) {
            return value === null || value === undefined ? "" : String(value);
        }

        function fuzzyScore(text, query) {
            if (query === "")
                return 0;

            let score = 0;
            let queryIndex = 0;
            let consecutive = 0;

            for (let index = 0; index < text.length && queryIndex < query.length; index++) {
                if (text[index] !== query[queryIndex]) {
                    consecutive = 0;
                    continue;
                }

                score += 10 + consecutive * 6;
                if (index === 0 || /[\s_-]/.test(text[index - 1]))
                    score += 8;
                consecutive++;
                queryIndex++;
            }

            return queryIndex === query.length ? score : -1;
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

        function queryPrefix() {
            const first = searchQuery.trim().charAt(0);
            return first === ">" || first === "?" || first === "@" ? first : "";
        }

        function queryText() {
            const query = searchQuery.trim();
            return queryPrefix() !== "" ? query.slice(1).trim() : query;
        }

        function categoryAllowed(category) {
            const prefix = queryPrefix();

            if (prefix === ">")
                return category === "ACTIONS";
            if (prefix === "?")
                return category === "ACTIONS";
            if (prefix === "@")
                return category === "WINDOWS";

            return selectedCategory === "ALL" || selectedCategory === category;
        }

        function selectCategory(offset) {
            selectedCategoryIndex = (selectedCategoryIndex + offset + categories.length)
                % categories.length;
            resultList.currentIndex = 0;
        }

        function buildResults() {
            const query = queryText();
            const normalizedQuery = query.toLowerCase();
            const results = [];
            const limit = 7;
            const applications = categoryAllowed("APPLICATIONS")
                ? DesktopEntries.applications.values.map(application => {
                if (application.noDisplay)
                    return null;

                const searchable = (textValue(application.name) + " "
                    + textValue(application.genericName) + " "
                    + textValue(application.comment) + " "
                    + textValue(application.keywords)).toLowerCase();
                const score = fuzzyScore(searchable, normalizedQuery);
                if (normalizedQuery !== "" && score < 0)
                    return null;

                return {
                    type: "application",
                    category: "APPLICATIONS",
                    title: textValue(application.name),
                    subtitle: textValue(application.genericName) || textValue(application.comment),
                    glyph: "󰀻",
                    score: score,
                    application: application
                };
            }).filter(result => result !== null)
                .sort((first, second) => second.score - first.score
                    || first.title.localeCompare(second.title))
                .slice(0, limit) : [];
            results.push(...applications);

            const bookmarks = categoryAllowed("BOOKMARKS") ? root.bookmarks.items.map(bookmark => {
                const searchable = (textValue(bookmark.label) + " "
                    + textValue(bookmark.url)).toLowerCase();
                const score = fuzzyScore(searchable, normalizedQuery);
                if (normalizedQuery !== "" && score < 0)
                    return null;

                return {
                    type: "bookmark",
                    category: "BOOKMARKS",
                    title: textValue(bookmark.label),
                    subtitle: textValue(bookmark.url),
                    glyph: textValue(bookmark.glyph) || "󰈹",
                    score: score,
                    bookmark: bookmark
                };
            }).filter(result => result !== null)
                .sort((first, second) => second.score - first.score
                    || first.title.localeCompare(second.title))
                .slice(0, limit) : [];
            results.push(...bookmarks);

            if (query !== "" && categoryAllowed("ACTIONS") && queryPrefix() !== ">") {
                results.push({
                    type: "search",
                    category: "ACTIONS",
                    title: "Search " + selectedSearchEngine.label + " for “" + query + "”",
                    subtitle: selectedSearchEngine.searchUrl,
                    glyph: selectedSearchEngine.glyph || "󰖟",
                    query: query
                });
            }

            const clipboard = categoryAllowed("CLIPBOARD") ? root.clipboardHistory.orderedEntries.map(entry => {
                const preview = textValue(entry.preview);
                const score = fuzzyScore(preview.toLowerCase(), normalizedQuery);
                if (normalizedQuery !== "" && score < 0)
                    return null;

                return {
                    type: "clipboard",
                    category: "CLIPBOARD",
                    title: preview,
                    subtitle: entry.image ? "Image clipboard entry" : "Copy to clipboard",
                    glyph: entry.image ? "󰋩" : "󰆏",
                    score: score,
                    entry: entry
                };
            }).filter(result => result !== null)
                .sort((first, second) => second.score - first.score)
                .slice(0, limit) : [];
            results.push(...clipboard);

            const toplevels = categoryAllowed("WINDOWS") ? root.workspaceService.switcherToplevels().map(toplevel => {
                const appClass = textValue(toplevel.lastIpcObject?.class
                    || toplevel.lastIpcObject?.initialClass || "application");
                const title = textValue(toplevel.title) || appClass;
                const score = fuzzyScore((title + " " + appClass).toLowerCase(), normalizedQuery);
                if (normalizedQuery !== "" && score < 0)
                    return null;

                return {
                    type: "window",
                    category: "WINDOWS",
                    title: title,
                    subtitle: appClass + (toplevel.workspace
                        ? "  •  workspace " + toplevel.workspace.id : ""),
                    glyph: "󰖯",
                    score: score,
                    toplevel: toplevel
                };
            }).filter(result => result !== null)
                .sort((first, second) => second.score - first.score)
                .slice(0, limit) : [];
            results.push(...toplevels);

            if (query !== "" && categoryAllowed("ACTIONS") && queryPrefix() !== "?") {
                results.push({
                    type: "command",
                    category: "ACTIONS",
                    title: "Run “" + query + "” in Kitty",
                    subtitle: "Open an interactive terminal",
                    glyph: "",
                    command: query
                });
            }

            if (categoryAllowed("ACTIONS") && queryPrefix() === "") {
                const actionItems = [
                    {
                        type: "settings",
                        category: "ACTIONS",
                        title: "Open shell settings",
                        subtitle: "Configure appearance, displays, widgets, and status bar",
                        glyph: "󰒓"
                    }
                ];
                const workspaceIds = root.workspaceService.workspacesForScreen(
                    modelData,
                    root.monitors.workspacesFor(
                        root.workspaceService.monitorDescriptionForScreen(modelData)
                    )
                );

                for (let index = 0; index < workspaceIds.length; index++) {
                    const workspaceId = workspaceIds[index];
                    actionItems.push({
                        type: "workspace",
                        category: "ACTIONS",
                        title: "Focus workspace " + workspaceId,
                        subtitle: root.workspaceService.isActive(workspaceId)
                            ? "Current workspace" : root.workspaceService.toplevelCount(workspaceId)
                                + " open windows",
                        glyph: "󰍹",
                        workspaceId: workspaceId
                    });
                }

                results.push(...actionItems.filter(result => {
                    const score = fuzzyScore((result.title + " " + result.subtitle).toLowerCase(),
                        normalizedQuery);
                    return normalizedQuery === "" || score >= 0;
                }).slice(0, limit));
            }

            return results;
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (results.length === 0)
                return;

            resultList.currentIndex = (resultList.currentIndex + offset
                + results.length) % results.length;
            resultList.positionViewAtIndex(resultList.currentIndex, ListView.Contain);
        }

        function selectSearchEngine(offset) {
            if (searchEngines.length === 0)
                return;

            selectedSearchEngineIndex = (selectedSearchEngineIndex + offset
                + searchEngines.length) % searchEngines.length;
            root.bookmarks.activeSearchEngineIndex = selectedSearchEngineIndex;
        }

        function activateCurrent() {
            if (!resultList.currentItem)
                return;

            const result = resultList.currentItem.result;
            if (result.type === "application") {
                result.application.execute();
            } else if (result.type === "bookmark") {
                actionProcess.command = [
                    "sh", "-c", "xdg-open \"$1\" >/dev/null 2>&1 &",
                    "unified-search-browser", result.bookmark.url
                ];
                actionProcess.running = true;
            } else if (result.type === "search") {
                actionProcess.command = [
                    "sh", "-c", "xdg-open \"$1\" >/dev/null 2>&1 &",
                    "unified-search-browser", searchUrlFor(result.query)
                ];
                actionProcess.running = true;
            } else if (result.type === "clipboard") {
                actionProcess.command = [
                    "sh", "-c", "cliphist decode \"$1\" | wl-copy", "cliphist",
                    String(result.entry.id)
                ];
                actionProcess.running = true;
            } else if (result.type === "window") {
                root.workspaceService.focusToplevel(result.toplevel);
            } else if (result.type === "command") {
                actionProcess.command = ["kitty", "-e", "sh", "-lc", result.command];
                actionProcess.running = true;
            } else if (result.type === "settings") {
                root.settingsRequested();
            } else if (result.type === "workspace") {
                root.workspaceService.switchTo(result.workspaceId);
            } else {
                return;
            }

            close();
        }

        onVisibleChanged: {
            if (!visible)
                return;

            searchQuery = "";
            selectedCategoryIndex = 0;
            selectedSearchEngineIndex = Math.max(0, Math.min(
                root.bookmarks.activeSearchEngineIndex, searchEngines.length - 1));
            root.clipboardHistory.refresh();
            resultList.currentIndex = 0;
            inputFocusTimer.restart();
        }

        Timer {
            id: inputFocusTimer

            interval: 1
            onTriggered: searchInput.forceActiveFocus()
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

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                TextField {
                    id: searchInput

                    width: parent.width
                    height: 46
                    placeholderText: "Search apps, bookmarks, clipboard, windows, or run a command"
                    placeholderTextColor: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize + 1
                    font.bold: true
                    leftPadding: 42
                    rightPadding: 146
                    selectByMouse: true
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
                        font.family: theme.fontFamily
                        font.pixelSize: 19
                    }

                    Rectangle {
                        id: engineSelector

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        height: 30
                        radius: root.appearance.radius
                        color: engineHover.hovered ? theme.surfaceHover
                            : Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.7)

                        HoverHandler {
                            id: engineHover
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
                        resultList.currentIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (event.modifiers & Qt.ControlModifier
                                && event.key === Qt.Key_Left) {
                            searchPanel.selectSearchEngine(-1);
                        } else if (event.modifiers & Qt.ControlModifier
                                && event.key === Qt.Key_Right) {
                            searchPanel.selectSearchEngine(1);
                        } else if (event.key === Qt.Key_Down) {
                            searchPanel.selectRelative(1);
                        } else if (event.key === Qt.Key_Up) {
                            searchPanel.selectRelative(-1);
                        } else if (event.key === Qt.Key_Tab) {
                            searchPanel.selectCategory(
                                event.modifiers & Qt.ShiftModifier ? -1 : 1
                            );
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            searchPanel.activateCurrent();
                        } else if (event.key === Qt.Key_Escape) {
                            searchPanel.close();
                        } else {
                            return;
                        }

                        event.accepted = true;
                    }
                }

                Item {
                    width: parent.width
                    height: 18

                    Text {
                        text: searchPanel.selectedCategory === "ALL"
                            ? "UNIFIED SEARCH" : searchPanel.selectedCategory
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        text: "Tab category  •  > command  •  ? web  •  @ windows"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 4
                    }
                }

                ListView {
                    id: resultList

                    width: parent.width
                    height: parent.height - searchInput.height - 18 - parent.spacing * 2
                    clip: true
                    spacing: 4
                    model: searchPanel.results
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: resultDelegate

                        required property var modelData
                        required property int index
                        readonly property var result: modelData
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property bool categoryStart: index === 0
                            || result.category !== searchPanel.results[index - 1].category

                        width: resultList.width
                        height: (categoryStart ? 24 : 0) + 52

                        Text {
                            visible: resultDelegate.categoryStart
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: resultDelegate.result.category
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 4
                            font.bold: true
                        }

                        Rectangle {
                            id: resultRow

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: resultDelegate.categoryStart ? 24 : 0
                            height: 52
                            radius: root.appearance.radius
                            color: resultDelegate.selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                                theme.accent.b, 0.2) : resultHover.hovered ? theme.surfaceHover
                                    : theme.backgroundSecondary
                            border.color: resultDelegate.selected ? theme.accent : "transparent"
                            border.width: resultDelegate.selected ? 1 : 0

                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }

                            HoverHandler {
                                id: resultHover
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                text: resultDelegate.result.glyph
                                color: resultDelegate.selected ? theme.accent : theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: 19
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 46
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: resultDelegate.result.title
                                    color: theme.text
                                    elide: Text.ElideRight
                                    font.family: theme.fontFamily
                                    font.pixelSize: root.appearance.textSize
                                    font.bold: resultDelegate.selected
                                }

                                Text {
                                    width: parent.width
                                    text: resultDelegate.result.subtitle
                                    color: theme.textMuted
                                    elide: Text.ElideRight
                                    font.family: theme.fontFamily
                                    font.pixelSize: root.appearance.textSize - 3
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    resultList.currentIndex = index;
                                    searchPanel.activateCurrent();
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: resultList.count === 0
                        text: "No matching results"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize
                    }
                }
            }
        }
    }
}
