import QtQuick

// Somewhere a dragged window can be dropped. Says which windows it takes and
// what a drop means, and containsDrag is true while one it takes is over it.
DropArea {
    id: root

    property var accepts: window => true

    signal windowDropped(QtObject window)

    keys: ["window"]

    onEntered: drag => drag.accepted = accepts(drag.source.window)
    onDropped: drop => {
        drop.accept();
        windowDropped(drop.source.window);
    }
}
