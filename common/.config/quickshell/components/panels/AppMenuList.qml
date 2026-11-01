import QtQuick
import "../../config" as Config
import "." as Panels

// One menu of the app menu model (components/AppMenuModel.js) drawn as a
// list: actions as rows, separators as rules and submenus opening in place,
// with a row on top to go back. Choosing an action hands it over through
// `actionChosen`; running it is up to whoever shows the list.
Column {
    id: root

    required property var appearance
    // The menu's items, as AppMenuModel describes them.
    property var items: []
    // The submenus opened, outermost first.
    property var openedSubmenus: []
    readonly property var shownItems: openedSubmenus.length > 0
        ? openedSubmenus[openedSubmenus.length - 1].items : items

    signal actionChosen(var action)

    function choose(index) {
        const item = shownItems[index];

        if (!item || item.enabled === false)
            return;
        if (item.kind === "submenu")
            openedSubmenus = openedSubmenus.concat([item]);
        else if (item.kind === "action")
            actionChosen(item.action);
    }

    function back() {
        openedSubmenus = openedSubmenus.slice(0, -1);
    }

    onItemsChanged: openedSubmenus = []
    spacing: 0

    Config.Theme {
        id: theme
    }

    Panels.PopupRow {
        appearance: root.appearance
        visible: root.openedSubmenus.length > 0
        width: root.width
        height: 30

        Panels.Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.openedSubmenus.length > 0
                ? "󰅁  " + root.openedSubmenus[root.openedSubmenus.length - 1].label : ""
            color: theme.textMuted
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize - 1
        }

        TapHandler {
            onTapped: root.back()
        }
    }

    Repeater {
        model: root.shownItems

        delegate: Panels.PopupRow {
            id: row

            required property var modelData
            required property int index
            readonly property bool separator: modelData.kind === "separator"
            readonly property bool itemEnabled: !separator && modelData.enabled !== false

            appearance: root.appearance
            width: root.width
            height: separator ? 9 : 30
            interactive: itemEnabled

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                height: 1
                visible: row.separator
                color: theme.border
            }

            Panels.Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: submenuMark.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.separator
                text: row.separator ? "" : row.modelData.label
                color: row.itemEnabled ? theme.text : theme.textDisabled
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
            }

            Panels.Text {
                id: submenuMark

                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.kind === "submenu"
                text: visible ? "›" : ""
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 1
            }

            TapHandler {
                enabled: row.itemEnabled
                onTapped: root.choose(row.index)
            }
        }
    }
}
