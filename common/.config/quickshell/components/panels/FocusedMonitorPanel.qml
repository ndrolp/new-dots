import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

// The window of a panel shown as a card in the centre of the focused
// monitor (the Printers and Android devices panels): one per screen, as a
// Variants delegate, shown while `open` on the focused monitor only. Escape
// or a click outside the card asks to close. What goes in the card is the
// panel's, inside its 16 px margin, and `contentHeight` sizes the card.
PanelWindow {
    id: panel

    required property var modelData
    required property var appearance
    property bool open: false
    // The layer-shell namespace ("ndro-shell-<panel>").
    property string layerNamespace: ""
    property real cardWidth: 520
    // How tall the contents want to be; the card stays on screen.
    property real contentHeight: 0
    default property alias content: body.data

    readonly property var monitor: Hyprland.monitorFor(modelData)
    readonly property bool focusedMonitor: Hyprland.focusedWorkspace
        && Hyprland.focusedWorkspace.monitor && monitor
        && Hyprland.focusedWorkspace.monitor.name === monitor.name

    signal closeRequested()

    screen: modelData
    visible: open && focusedMonitor
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.namespace: layerNamespace
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    onVisibleChanged: {
        if (visible)
            card.forceActiveFocus();
    }

    Config.Theme {
        id: theme
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        TapHandler {
            onTapped: panel.closeRequested()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(parent.width - 64, panel.cardWidth)
        height: Math.min(parent.height - 80, panel.contentHeight + 32)
        radius: panel.appearance.radius
        color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.78)
        border.color: theme.border
        border.width: 1
        focus: true

        // Clicks on the card don't reach the backdrop behind it.
        TapHandler {}

        Keys.onEscapePressed: panel.closeRequested()

        Item {
            id: body

            anchors.fill: parent
            anchors.margins: 16
        }
    }
}
