import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property alias favorites: settings.favorites
    property alias recent: settings.recent

    function isFavorite(applicationId) {
        return favorites.includes(applicationId);
    }

    function toggleFavorite(applicationId) {
        favorites = isFavorite(applicationId)
            ? favorites.filter(id => id !== applicationId)
            : [applicationId].concat(favorites);
    }

    function moveFavorite(applicationId, offset) {
        const from = favorites.indexOf(applicationId);
        const to = from + offset;

        if (from < 0 || to < 0 || to >= favorites.length)
            return;

        const updated = favorites.slice();
        const moved = updated.splice(from, 1)[0];
        updated.splice(to, 0, moved);
        favorites = updated;
    }

    function favoriteIndex(applicationId) {
        return favorites.indexOf(applicationId);
    }

    function recordLaunch(applicationId) {
        recent = [applicationId].concat(recent.filter(id => id !== applicationId)).slice(0, 20);
    }

    function recentIndex(applicationId) {
        return recent.indexOf(applicationId);
    }

    property var settingsFile: FileView {
        id: settingsFile

        path: Qt.resolvedUrl("launcher.json")
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

            property var favorites: []
            property var recent: []
        }
    }
}
