import QtQuick

// The settings panel inside a capsule (ConfigPanel.qml): modules/Settings.qml
// opens it here on a monitor whose bar is a capsule, instead of centered. Same
// size and layout. Done or Escape closes it, and a click outside doesn't: it
// only takes the keyboard away until the panel is pressed again. Built only
// while open: every bar has one.
BarPopup {
    id: root

    // The settings panel module (modules/Settings.qml).
    required property var feature
    popup: "settings"
    // The panel's own size (ConfigPanel's implicit size), whatever the
    // capsule's row under it.
    popupWidth: panel.implicitWidth
    closesOnClickOutside: false

    function close() {
        popups.popupClosed(popup);
    }

    onShownChanged: {
        if (shown)
            keys.forceActiveFocus();
    }

    Item {
        id: keys

        width: parent.width
        height: panel.implicitHeight
        focus: true

        Keys.onEscapePressed: root.close()

        Loader {
            id: panel

            // Unsized, it takes the panel's implicit size.
            anchors.horizontalCenter: parent.horizontalCenter
            active: root.open || root.reveal > 0

            sourceComponent: ConfigPanel {
                appearance: root.feature.appearance
                monitors: root.feature.monitors
                wallpapers: root.feature.wallpapers
                bookmarks: root.feature.bookmarks
                plugins: root.feature.plugins
                cava: root.feature.cava
                monitorSetups: root.feature.monitorSetups
                windowAppearance: root.feature.windowAppearance
                // The popup's surface is its background and border.
                color: "transparent"
                border.width: 0

                onCloseRequested: root.close()
                // Opened again, or moved to the centered position, it comes
                // back showing this.
                onViewChanged: root.feature.view = view
            }

            onLoaded: item.restoreView(root.feature.view)
        }

        // Opened at a section while already open here.
        Connections {
            target: root.feature

            function onSectionRequested(section) {
                if (root.open && panel.item)
                    panel.item.openSection(section);
            }
        }
    }
}
