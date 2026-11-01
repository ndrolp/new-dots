import Quickshell.Hyprland
import QtQuick
import "../../config" as Config
import ".." as Components
import "../AppMenuModel.js" as AppMenuModel
import "../FocusedWindow.js" as FocusedWindow

// The app menu bar element: one title per menu of AppMenuModel, the focused
// app's name in bold first (its .desktop Name, or its appId), then the
// app's own menus when it exports them (File, Edit...), then Window. The
// app's titles that don't fit `menusMaximumWidth` go into a "»" menu before
// Window. Clicking a title opens that menu as a Popup (`menuId` says which).
// It follows the focused window like CurrentApp, shown only on the focused
// monitor's bar. With no window focused there it shows "Desktop" and the
// Desktop menu.
Item {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var monitorScreen
    // The shell's services/AppMenuBridge.qml, for the app's own menus.
    property var bridge: null
    property bool enabled: true
    property bool popupOpen: false
    // The menu the Popup shows: the one whose title was clicked last.
    property string menuId: ""
    signal popupRequested()

    readonly property var monitor: Hyprland.monitorFor(monitorScreen)
    readonly property var currentMenus: {
        // Measured again when the font changes.
        titleMetrics.font;
        boldTitleMetrics.font;
        const widths = source.menus.map((menu, index) => titleWidth(menu.title, index === 0));
        return AppMenuModel.overflowSplit(source.menus, widths, menusMaximumWidth, titleWidth("»", false))
            .map(menu => ({ id: menu.id, title: menu.title }));
    }
    // Held while its Popup is open, so the titles don't move under it.
    property var menus: currentMenus
    readonly property real titleMaximumWidth: monitorScreen
        ? Math.max(120, Math.min(260, monitorScreen.width * 0.12)) : 260
    // How wide all the titles may get together.
    readonly property real menusMaximumWidth: monitorScreen ? Math.max(400, monitorScreen.width * 0.4) : 800
    // Where the open menu's title sits in this element, so the Popup opens
    // under it rather than under the whole element.
    readonly property var popupTriggerArea: {
        const index = menus.findIndex(menu => menu.id === menuId);
        const title = index >= 0 && titleRepeater.count > index ? titleRepeater.itemAt(index) : null;
        return title ? { x: background.x + titleRow.x + title.x, width: title.width } : null;
    }

    // How wide a title is drawn, as each title below draws it.
    function titleWidth(text, bold) {
        const metrics = bold ? boldTitleMetrics : titleMetrics;
        return Math.min(titleMaximumWidth, Math.ceil(metrics.advanceWidth(text))) + 12;
    }

    // Opens the menu `id`; while the Popup is open on another menu it
    // switches to this one instead of closing.
    function titleClicked(id) {
        const switching = popupOpen && menuId !== id;
        menuId = id;
        if (!switching)
            popupRequested();
    }

    visible: enabled && menus.length > 0 && FocusedWindow.onFocusedMonitor(monitor, Hyprland.focusedWorkspace)
    width: visible ? background.width : 0
    height: background.height

    onCurrentMenusChanged: {
        if (!popupOpen)
            menus = currentMenus;
    }
    onPopupOpenChanged: {
        if (!popupOpen)
            menus = currentMenus;
    }

    Components.AppMenuSource {
        id: source

        bridge: root.bridge
    }

    // The app's own menus are only looked for while some app menu shows.
    onEnabledChanged: {
        if (bridge)
            bridge.setUsing(root, enabled);
    }
    onBridgeChanged: {
        if (bridge)
            bridge.setUsing(root, enabled);
    }
    Component.onCompleted: {
        if (bridge)
            bridge.setUsing(root, enabled);
    }
    Component.onDestruction: {
        if (bridge)
            bridge.setUsing(root, false);
    }

    FontMetrics {
        id: titleMetrics

        font.family: theme.fontFamily
        font.pixelSize: root.appearance.textSize
    }

    FontMetrics {
        id: boldTitleMetrics

        font.family: theme.fontFamily
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    Config.Theme {
        id: theme
    }

    Behavior on width {
        NumberAnimation {
            duration: root.appearance.motion.medium
            easing.type: root.appearance.motion.easing
        }
    }

    Rectangle {
        id: background

        width: titleRow.width + 8
        height: root.appearance.barTransparent
            ? root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
            : Math.max(1, root.appearance.barHeight - (root.appearance.elementVerticalPadding * 2))
        radius: root.appearance.radius
        color: root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
            || root.grouped ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.grouped ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

        Row {
            id: titleRow

            anchors.centerIn: parent

            Repeater {
                id: titleRepeater

                model: root.menus

                Rectangle {
                    id: title

                    required property var modelData
                    required property int index
                    readonly property bool open: root.popupOpen && root.menuId === modelData.id

                    width: name.width + 12
                    height: Math.max(1, background.height - 4)
                    radius: Math.max(0, root.appearance.radius - 2)
                    color: hover.hovered || open ? theme.surfaceHover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: root.appearance.motion.short
                        }
                    }

                    HoverHandler {
                        id: hover
                    }

                    Text {
                        id: name

                        // Centers the capital letters, not the line box.
                        anchors.centerIn: parent
                        anchors.alignWhenCentered: false
                        anchors.verticalCenterOffset: height / 2 - (baselineOffset - nameMetrics.capitalHeight / 2)
                        width: Math.min(root.titleMaximumWidth, implicitWidth)
                        text: title.modelData.title
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize
                        // The app's name stands out from the other titles.
                        font.bold: title.index === 0

                        FontMetrics {
                            id: nameMetrics

                            font: name.font
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.titleClicked(title.modelData.id)
                    }
                }
            }
        }
    }
}
