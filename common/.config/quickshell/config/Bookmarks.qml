import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property alias items: settings.items
    property alias searchEngines: settings.searchEngines
    property alias activeSearchEngineIndex: settings.activeSearchEngineIndex

    function update(index, field, value) {
        if (index < 0 || index >= items.length)
            return;

        const updated = items.slice();
        updated[index] = Object.assign({}, updated[index]);
        updated[index][field] = value;
        items = updated;
    }

    function add() {
        const updated = items.slice();
        updated.push({
            label: "New bookmark",
            url: "",
            glyph: "󰈹"
        });
        items = updated;
    }

    function remove(index) {
        if (index < 0 || index >= items.length)
            return;

        const updated = items.slice();
        updated.splice(index, 1);
        items = updated;
    }

    function move(from, to) {
        if (from < 0 || from >= items.length || to < 0 || to >= items.length
                || from === to)
            return;

        const updated = items.slice();
        const moved = updated.splice(from, 1)[0];
        updated.splice(to, 0, moved);
        items = updated;
    }

    function updateSearchEngine(index, field, value) {
        if (index < 0 || index >= searchEngines.length)
            return;

        const updated = searchEngines.slice();
        updated[index] = Object.assign({}, updated[index]);
        updated[index][field] = value;
        searchEngines = updated;
    }

    function addSearchEngine() {
        const updated = searchEngines.slice();
        updated.push({
            label: "New engine",
            searchUrl: "https://www.google.com/search?q=%s",
            glyph: "󰖟"
        });
        searchEngines = updated;
        activeSearchEngineIndex = updated.length - 1;
    }

    function removeSearchEngine(index) {
        if (searchEngines.length <= 1 || index < 0 || index >= searchEngines.length)
            return;

        const updated = searchEngines.slice();
        updated.splice(index, 1);
        searchEngines = updated;
        activeSearchEngineIndex = Math.min(activeSearchEngineIndex, updated.length - 1);
    }

    function moveSearchEngine(from, to) {
        if (from < 0 || from >= searchEngines.length || to < 0
                || to >= searchEngines.length || from === to)
            return;

        const updated = searchEngines.slice();
        const moved = updated.splice(from, 1)[0];
        updated.splice(to, 0, moved);
        searchEngines = updated;

        if (activeSearchEngineIndex === from)
            activeSearchEngineIndex = to;
        else if (from < activeSearchEngineIndex && activeSearchEngineIndex <= to)
            activeSearchEngineIndex--;
        else if (to <= activeSearchEngineIndex && activeSearchEngineIndex < from)
            activeSearchEngineIndex++;
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("bookmarks.json")
        atomicWrites: true
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: settings

            property int activeSearchEngineIndex: 0
            property var searchEngines: [
                {
                    label: "Google",
                    searchUrl: "https://www.google.com/search?q=%s",
                    glyph: "󰖟"
                }
            ]
            property var items: [
                { label: "Netflix", url: "https://www.netflix.com", glyph: "󰝆" },
                { label: "YouTube", url: "https://www.youtube.com", glyph: "󰗃" },
                { label: "Nerd Fonts", url: "https://www.nerdfonts.com/cheat-sheet", glyph: "󰛓" },
                { label: "AnimeFLV", url: "https://www3.animeflv.net", glyph: "󰆉" },
                { label: "Wallhaven", url: "https://wallhaven.cc", glyph: "󰸉" },
                { label: "GitHub", url: "https://github.com", glyph: "󰊤" },
                { label: "Copilot Docs", url: "https://docs.github.com/copilot", glyph: "󰧑" },
                { label: "Arch Wiki", url: "https://wiki.archlinux.org", glyph: "󰣇" },
                { label: "MDN Web Docs", url: "https://developer.mozilla.org", glyph: "󰖟" },
                { label: "ChatGPT", url: "https://chatgpt.com", glyph: "󰚩" }
            ]
        }
    }
}
