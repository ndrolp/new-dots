import QtQuick
import Qt.labs.folderlistmodel

// The wallpapers (images) in the folder at `path`, by name. Each row knows its
// own file (the filePath role, and pathAt): when the folder changes while the
// old one is still being listed, the old folder's rows can still arrive for a
// moment, so a path is never the new folder plus a row's name.
FolderListModel {
    property string path: ""

    // The file of row `index`, or "" when there is no such row.
    function pathAt(index) {
        if (index < 0 || index >= count)
            return "";
        return get(index, "filePath");
    }

    folder: path === "" ? "" : Qt.resolvedUrl(path)
    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
    showDirs: false
}
