import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var workspaceService
    property bool open: false
    property string selectedAddress: ""
    property int iconRefreshStep: 0
    readonly property var switcherWindows: workspaceService.switcherToplevels()

    signal openRequested()
    signal closeRequested()

    model: Quickshell.screens

    function windows() {
        return switcherWindows;
    }

    function resetSelection() {
        const toplevels = windows();
        const active = toplevels.find(toplevel => toplevel.activated);
        selectedAddress = active ? active.address : toplevels.length > 0 ? toplevels[0].address : "";
    }

    function selectRelative(offset) {
        const toplevels = windows();

        if (toplevels.length === 0)
            return;

        let index = toplevels.findIndex(toplevel => toplevel.address === selectedAddress);
        if (index < 0)
            index = 0;
        selectedAddress = toplevels[(index + offset + toplevels.length) % toplevels.length].address;
    }

    function activateSelected(closeAfterActivate) {
        const toplevel = windows().find(window => window.address === selectedAddress);

        if (!toplevel)
            return;

        workspaceService.focusToplevel(toplevel);
        if (closeAfterActivate)
            close();
    }

    function cycle(offset) {
        if (!open) {
            openRequested();
            resetSelection();
        }

        selectRelative(offset);
    }

    function show() {
        openRequested();
        resetSelection();
    }

    function close() {
        if (!open)
            return;

        closeRequested();
    }

    onOpenChanged: {
        if (open) {
            iconRefreshStep = 0;
            iconRefreshTimer.restart();
        }
    }

    onSwitcherWindowsChanged: {
        if (open) {
            iconRefreshStep = 0;
            iconRefreshTimer.restart();
        }
    }

    property var iconRefreshTimer: Timer {
        interval: 250
        onTriggered: {
            root.iconRefreshStep++;

            if (root.iconRefreshStep < 4)
                restart();
        }
    }

    delegate: PanelWindow {
        id: switcher

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-window-switcher"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Config.Theme {
            id: theme
        }

        onVisibleChanged: {
            if (visible)
                keyboardFocus.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: root.close()
            }
        }

        FocusScope {
            id: keyboardFocus

            anchors.fill: parent
            focus: switcher.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right
                        || event.key === Qt.Key_Down) {
                    root.selectRelative(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                    root.selectRelative(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.activateSelected(true);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt) {
                    root.activateSelected(true);
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: switcherCard

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 680)
            height: Math.min(parent.height - 96, Math.max(154,
                82 + windowList.contentHeight + 58))
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.92)
            border.color: theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Item {
                    width: parent.width
                    height: 21

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WINDOW SWITCHER"
                        color: theme.text
                        font.pixelSize: root.appearance.textSize + 1
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.windows().length + " windows"
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 2
                    }
                }

                ListView {
                    id: windowList

                    width: parent.width
                    height: parent.height - 58
                    clip: true
                    spacing: 5
                    model: root.windows()
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: windowRow

                        required property var modelData
                        readonly property var toplevel: modelData
                        readonly property bool selected: root.selectedAddress === toplevel.address
                        readonly property string appClass: String(
                            toplevel.lastIpcObject?.class
                                || toplevel.lastIpcObject?.initialClass
                                || "application"
                        ).toLowerCase()

                        width: windowList.width
                        height: 52
                        radius: root.appearance.radius
                        color: selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                            theme.accent.b, 0.2) : rowHover.hovered ? theme.surfaceHover
                                : theme.backgroundSecondary
                        border.color: selected ? theme.accent : "transparent"
                        border.width: selected ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        HoverHandler {
                            id: rowHover
                        }

                        Loader {
                            id: applicationIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            active: root.iconRefreshStep % 2 === 0
                            sourceComponent: Component {
                                Image {
                                    anchors.fill: parent
                                    cache: false
                                    source: "image://icon/" + windowRow.appClass
                                        + "?fallback=application-x-executable"
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: applicationIcon
                            radius: root.appearance.radius
                            visible: applicationIcon.item
                                && applicationIcon.item.status !== Image.Ready
                            color: theme.surface

                            Text {
                                anchors.centerIn: parent
                                text: "󰣆"
                                color: theme.textMuted
                                font.pixelSize: 15
                            }
                        }

                        Column {
                            anchors.left: applicationIcon.right
                            anchors.leftMargin: 10
                            anchors.right: workspaceLabel.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: windowRow.toplevel.title || windowRow.appClass
                                color: theme.text
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize
                                font.bold: windowRow.selected
                            }

                            Text {
                                width: parent.width
                                text: windowRow.appClass
                                color: theme.textMuted
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize - 3
                            }
                        }

                        Text {
                            id: workspaceLabel

                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍹 " + windowRow.toplevel.workspace.id
                            color: windowRow.selected ? theme.accent : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 2
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: {
                                root.selectedAddress = windowRow.toplevel.address;
                                root.activateSelected(true);
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.windows().length === 0
                    text: "No switchable windows"
                    color: theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: root.appearance.textSize
                }
            }
        }
    }
}
