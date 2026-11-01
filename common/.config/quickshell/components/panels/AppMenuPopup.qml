import QtQuick
import ".." as Components

// The app menu's Popup: the focused app's app-name menu, from AppMenuModel.
// Choosing an item runs its action and closes the popup.
BarPopup {
    id: root

    // Which of AppMenuModel's menus to show; the first (the app-name menu)
    // when none is named.
    property string menuId: ""
    // The menus as they were when it opened, so they hold still while it
    // has the keyboard.
    property var shownMenus: []
    readonly property var menu: shownMenus.find(candidate => candidate.id === menuId)
        || shownMenus[0] || null

    onOpenChanged: {
        if (open)
            shownMenus = source.menus;
    }

    popup: "appMenu"
    edge: "left"
    implicitWidth: 260

    Components.AppMenuSource {
        id: source
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
