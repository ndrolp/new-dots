import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    property bool open: false
    property int selectedWorkspaceId: -1

    signal closeRequested()

    model: Quickshell.screens

    function workspaceIds(screen) {
        return workspaceService.workspacesForScreen(
            screen,
            monitors.workspacesFor(workspaceService.monitorDescriptionForScreen(screen))
        );
    }

    function resetSelection() {
        selectedWorkspaceId = Hyprland.focusedWorkspace
            ? Hyprland.focusedWorkspace.id : -1;
    }

    function selectRelative(offset, screen) {
        const ids = workspaceIds(screen);

        if (ids.length === 0)
            return;

        let index = ids.indexOf(selectedWorkspaceId);
        if (index < 0)
            index = 0;
        selectedWorkspaceId = ids[(index + offset + ids.length) % ids.length];
    }

    function activateSelected() {
        if (selectedWorkspaceId < 1)
            return;

        workspaceService.switchTo(selectedWorkspaceId);
        close();
    }

    function close() {
        if (!open)
            return;

        closeRequested();
    }

    onOpenChanged: {
        if (open)
            resetSelection();
    }

    delegate: PanelWindow {
        id: overview

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property int columns: width >= 1300 ? 4 : width >= 900 ? 3 : 2

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-workspace-overview"
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
            focus: overview.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Right) {
                    root.selectRelative(1, modelData);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    root.selectRelative(-1, modelData);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    root.selectRelative(columns, modelData);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    root.selectRelative(-columns, modelData);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.activateSelected();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }
        }

        Rectangle {
            id: overviewCard

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 1160)
            height: Math.min(parent.height - 96, 720)
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
                        text: "WORKSPACE OVERVIEW"
                        color: theme.text
                        font.pixelSize: root.appearance.textSize + 1
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Arrow keys to select · Enter to focus"
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                GridView {
                    id: workspaceGrid

                    width: parent.width
                    height: parent.height - 42
                    clip: true
                    cellWidth: width / overview.columns
                    cellHeight: 156
                    model: root.workspaceIds(overview.modelData)
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: workspaceTile

                        required property var modelData
                        readonly property int workspaceId: modelData
                        readonly property bool active: root.workspaceService.isActive(workspaceId)
                        readonly property bool selected: root.selectedWorkspaceId === workspaceId
                        readonly property var windows: root.workspaceService
                            .toplevelsForWorkspace(workspaceId)

                        width: workspaceGrid.cellWidth - 8
                        height: workspaceGrid.cellHeight - 8
                        radius: root.appearance.radius
                        color: selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                            theme.accent.b, 0.2) : active ? theme.surfaceHover
                                : theme.backgroundSecondary
                        border.color: selected ? theme.accent : active ? theme.border : "transparent"
                        border.width: selected || active ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 20

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰍹  " + workspaceTile.workspaceId
                                    color: workspaceTile.selected ? theme.accent : theme.text
                                    font.pixelSize: root.appearance.textSize
                                    font.bold: true
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: workspaceTile.active ? "ACTIVE" : workspaceTile.windows.length
                                        + (workspaceTile.windows.length === 1 ? " window" : " windows")
                                    color: workspaceTile.active ? theme.accent : theme.textMuted
                                    font.pixelSize: root.appearance.textSize - 4
                                    font.bold: workspaceTile.active
                                }
                            }

                            Repeater {
                                model: workspaceTile.windows.slice(0, 3)

                                delegate: Rectangle {
                                    id: windowEntry

                                    required property var modelData
                                    readonly property var toplevel: modelData
                                    readonly property string appClass: String(
                                        toplevel.lastIpcObject?.class
                                            || toplevel.lastIpcObject?.initialClass
                                            || "application"
                                    ).toLowerCase()

                                    width: parent.width
                                    height: 27
                                    radius: root.appearance.radius
                                    color: windowHover.hovered ? theme.surfaceHover : theme.surface

                                    HoverHandler {
                                        id: windowHover
                                    }

                                    IconImage {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        source: "image://icon/" + windowEntry.appClass
                                            + "?fallback=application-x-executable"
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 28
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: windowEntry.toplevel.title || windowEntry.appClass
                                        color: theme.text
                                        elide: Text.ElideRight
                                        font.pixelSize: root.appearance.textSize - 4
                                    }

                                    TapHandler {
                                        onTapped: {
                                            root.workspaceService.focusToplevel(windowEntry.toplevel);
                                            root.close();
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: workspaceTile.windows.length > 3
                                text: "+" + (workspaceTile.windows.length - 3) + " more"
                                color: theme.textMuted
                                font.pixelSize: root.appearance.textSize - 4
                            }

                            Text {
                                visible: workspaceTile.windows.length === 0
                                text: "Empty workspace"
                                color: theme.textDisabled
                                font.pixelSize: root.appearance.textSize - 3
                            }
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                root.selectedWorkspaceId = workspaceTile.workspaceId;
                                root.workspaceService.switchTo(workspaceTile.workspaceId);
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
