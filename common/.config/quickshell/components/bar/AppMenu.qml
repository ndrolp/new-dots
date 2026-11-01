import Quickshell.Hyprland
import QtQuick
import "../../config" as Config
import ".." as Components

// The app menu bar element: the focused app's name in bold (its .desktop
// Name, or its appId), opening the app-name menu as a Popup. It follows the
// focused window like CurrentApp: shown only on the focused monitor's bar,
// and only while a window there is focused.
Item {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var monitorScreen
    property bool enabled: true
    property bool popupOpen: false
    signal popupRequested()

    readonly property var monitor: Hyprland.monitorFor(monitorScreen)
    // The first menu's title: the app's name, as the app-name menu is first.
    readonly property string currentTitle: source.menus.length > 0 ? source.menus[0].title : ""
    // Held while its Popup is open, so the element doesn't move under it.
    property string title: currentTitle
    readonly property real titleMaximumWidth: monitorScreen
        ? Math.max(120, Math.min(260, monitorScreen.width * 0.12)) : 260

    visible: enabled && title !== "" && monitor !== null && Hyprland.focusedWorkspace
        && Hyprland.focusedWorkspace.monitor !== null
        && Hyprland.focusedWorkspace.monitor.name === monitor.name
    width: visible ? background.width : 0
    height: background.height

    onCurrentTitleChanged: {
        if (!popupOpen)
            title = currentTitle;
    }
    onPopupOpenChanged: {
        if (!popupOpen)
            title = currentTitle;
    }

    Components.AppMenuSource {
        id: source
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

        width: name.width + 16
        height: root.appearance.barTransparent
            ? root.appearance.workspaceButtonSize + (root.appearance.pillVerticalPadding * 2)
            : Math.max(1, root.appearance.barHeight - (root.appearance.elementVerticalPadding * 2))
        radius: root.appearance.radius
        color: hover.hovered || root.popupOpen ? theme.surfaceHover
            : root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.grouped ? "transparent" : theme.surface
        border.width: root.appearance.barTransparentBorder && !root.grouped ? 1 : 0
        border.color: root.appearance.barTransparentBorder ? theme.border : "transparent"

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
            text: root.title
            color: theme.text
            elide: Text.ElideRight
            font.pixelSize: root.appearance.textSize
            font.bold: true

            FontMetrics {
                id: nameMetrics

                font: name.font
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.popupRequested()
        }
    }
}
