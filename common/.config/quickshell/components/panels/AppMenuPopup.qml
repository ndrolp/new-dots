import QtQuick
import ".." as Components
import "../AppMenuModel.js" as AppMenuModel

// The app menu's Popup: one of the focused window's menus from AppMenuModel
// (the app-name menu, the app's own, Window, the "»" overflow...), the one
// whose title was clicked.
// Choosing an item runs its action and closes the popup.
BarPopup {
    id: root

    // Which of AppMenuModel's menus to show (AppMenuModel.findMenu); the
    // first (the app-name menu) when none is named.
    property string menuId: ""
    // The app menu module (modules/AppMenu.qml).
    property var appMenu: null
    // The menus as they were when it opened, so they hold still while it
    // has the keyboard.
    property var shownMenus: []
    readonly property var menu: AppMenuModel.findMenu(shownMenus, menuId)

    onOpenChanged: {
        if (open)
            shownMenus = source.menus;
    }

    popup: "appMenu"
    edge: "left"
    implicitWidth: 260

    Components.AppMenuSource {
        id: source

        appMenu: root.appMenu
    }

    Column {
        width: parent.width
        spacing: 6

        PopupTitle {
            appearance: root.appearance
            width: parent.width
            leftPadding: 10
            text: root.menu ? root.menu.title : ""
        }

        AppMenuList {
            width: parent.width
            appearance: root.appearance
            items: root.menu ? root.menu.items : []

            onActionChosen: function(action) {
                source.run(action);
                root.popups.popupClosed(root.popup);
            }
        }
    }
}
