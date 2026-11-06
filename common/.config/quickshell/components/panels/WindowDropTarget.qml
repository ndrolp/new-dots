import QtQuick
import "WorkspaceOverview.js" as WorkspaceOverview

// Somewhere a dragged window can be dropped to move it to `workspace`. It takes
// only a window that would move, and containsDrag is true while one is over it.
DropArea {
    id: root

    required property int workspace

    signal windowDropped(QtObject window)

    keys: ["window"]

    onEntered: drag => drag.accepted = WorkspaceOverview.movesTo(
        drag.source.window.lastIpcObject, workspace)
    onDropped: drop => {
        drop.accept();
        windowDropped(drop.source.window);
    }
}
