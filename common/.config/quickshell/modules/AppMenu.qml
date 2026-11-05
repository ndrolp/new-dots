import Quickshell.Io
import QtQuick
import "SwitchTo.js" as SwitchTo
import "../components/AppMenuModel.js" as AppMenuModel
import "../components/panels" as Panels

// The app menu: what every place that shows it shares (its bar element and
// Popup, the popover), handed to them as one object: the bridge to apps'
// own menus (`bridge`) and opening the panels its Desktop menu names
// (`openPanel`). It is also the popover (SUPER+A, `app-menu` IPC): the
// focused app's menus at the cursor, which is what it opens and closes.
Feature {
    id: root

    required property var appearance
    // The bar module, whose app menu Popup closes when a panel opens.
    required property var bar
    // The shell's services/AppMenuBridge.qml.
    required property var bridge
    // The panels the Desktop menu opens.
    required property var unifiedSearch
    required property var settings
    required property var wallpaperSelector

    // Closes the app menu (its Popup or the popover) and opens `panel`
    // (an AppMenuModel.panels name) in its place, or leaves it open if it
    // already is; nothing happens while that panel's plugin is off.
    function openPanel(panel) {
        const features = {};
        features[AppMenuModel.panels.unifiedSearch] = unifiedSearch;
        features[AppMenuModel.panels.settings] = settings;
        features[AppMenuModel.panels.wallpaperSelector] = wallpaperSelector;
        const other = features[panel];
        if (!other)
            return;
        // Search opens with an empty field.
        if (other === unifiedSearch && !unifiedSearch.open)
            unifiedSearch.query = "";
        SwitchTo.switchTo(() => {
            root.bar.closePopup();
            root.open = false;
        }, other);
    }

    Panels.AppMenuPopover {
        appearance: root.appearance
        appMenu: root
        open: root.open

        onCloseRequested: root.open = false
    }

    IpcHandler {
        target: "app-menu"

        function toggle() {
            root.toggle();
        }
    }
}
