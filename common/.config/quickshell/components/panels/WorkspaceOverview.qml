import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../config" as Config
import "../IconSource.js" as IconSource
import "WorkspaceOverview.js" as WorkspaceOverview

Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    property bool open: false
    property int selectedWorkspaceId: -1
    // The screen it opened on, which it stays on until it closes. Empty while
    // closed, and kept apart from `open` so no other screen shows it meanwhile.
    property string shownOn: ""
    readonly property var groups: WorkspaceOverview.groups(
        connectedMonitors(),
        workspaceService.existingWorkspaces(),
        workspaceService.workspaceRules
    )

    signal closeRequested()

    model: Quickshell.screens

    function connectedMonitors() {
        return Quickshell.screens.map(screen => {
            const description = workspaceService.monitorDescriptionForScreen(screen);

            return {
                name: screen.name,
                description: description,
                x: screen.x,
                y: screen.y,
                width: screen.width,
                height: screen.height,
                workspaces: monitors.workspacesFor(description)
            };
        });
    }

    function resetSelection() {
        selectedWorkspaceId = Hyprland.focusedWorkspace
            ? Hyprland.focusedWorkspace.id : -1;
    }

    function selectRelative(offset) {
        selectedWorkspaceId = WorkspaceOverview.stepped(
            WorkspaceOverview.workspaceIds(groups), selectedWorkspaceId, offset);
    }

    // Moves a row up or down within the monitor holding the selection.
    function selectRow(direction, fit) {
        const monitor = fit.monitors[WorkspaceOverview.monitorHolding(groups, selectedWorkspaceId)];

        if (monitor !== undefined) {
            selectedWorkspaceId = WorkspaceOverview.stepped(
                monitor.workspaces, selectedWorkspaceId, direction * monitor.columns);
        }
    }

    function selectEnd(last) {
        const ids = WorkspaceOverview.workspaceIds(groups);

        selectedWorkspaceId = ids.length > 0 ? ids[last ? ids.length - 1 : 0] : -1;
    }

    function activateSelected() {
        if (selectedWorkspaceId < 1)
            return;

        workspaceService.switchTo(selectedWorkspaceId);
        close();
    }

    function createWorkspace() {
        const id = WorkspaceOverview.nextWorkspace(groups, shownOn);

        if (id === null)
            return;

        selectedWorkspaceId = id;
        workspaceService.switchTo(id);
        close();
    }

    function close() {
        if (!open)
            return;

        closeRequested();
    }

    onOpenChanged: {
        if (open) {
            Hyprland.refreshToplevels();
            workspaceService.refreshWorkspaceRules();
            resetSelection();
        }

        shownOn = open && Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    }

    delegate: PanelWindow {
        id: overview

        required property var modelData
        readonly property bool shown: root.shownOn === modelData.name
        property real reveal: shown ? 1 : 0

        readonly property int padding: 40
        readonly property int hintHeight: 24
        readonly property var fit: WorkspaceOverview.layout(
            root.groups,
            width - padding * 2,
            height - padding * 2 - hintHeight,
            {
                tile: 10,
                monitor: 32,
                header: 30,
                maxTileHeight: height / 3
            }
        )

        screen: modelData
        visible: reveal > 0
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

        Behavior on reveal {
            NumberAnimation {
                duration: root.appearance.motion.short
                easing.type: root.appearance.motion.easing
            }
        }

        onVisibleChanged: {
            if (visible)
                keyboardFocus.forceActiveFocus();
        }

        Item {
            anchors.fill: parent
            opacity: overview.reveal

            Rectangle {
                anchors.fill: parent
                enabled: overview.shown
                color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.85)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            FocusScope {
                id: keyboardFocus

                anchors.fill: parent
                focus: overview.visible

                Keys.onPressed: event => {
                    event.accepted = overview.shown;

                    if (!overview.shown)
                        return;

                    if (event.key === Qt.Key_Right)
                        root.selectRelative(1);
                    else if (event.key === Qt.Key_Left)
                        root.selectRelative(-1);
                    else if (event.key === Qt.Key_Down)
                        root.selectRow(1, overview.fit);
                    else if (event.key === Qt.Key_Up)
                        root.selectRow(-1, overview.fit);
                    else if (event.key === Qt.Key_Home)
                        root.selectEnd(false);
                    else if (event.key === Qt.Key_End)
                        root.selectEnd(true);
                    else if (event.key === Qt.Key_N || event.key === Qt.Key_Plus)
                        root.createWorkspace();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space)
                        root.activateSelected();
                    else if (event.key === Qt.Key_Escape)
                        root.close();
                    else
                        event.accepted = false;
                }
            }

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -overview.hintHeight / 2
                enabled: overview.shown
                spacing: 32

                Repeater {
                    // Only the screen it's on builds its tiles.
                    model: overview.visible ? overview.fit.monitors : []

                    delegate: Column {
                        id: monitorGroup

                        required property var modelData
                        readonly property var group: modelData

                        width: group.width

                        Item {
                            width: parent.width
                            height: 30

                            Text {
                                anchors.left: parent.left
                                anchors.right: newWorkspaceButton.visible
                                    ? newWorkspaceButton.left : parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: monitorGroup.group.name
                                color: theme.text
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize
                                font.bold: true
                            }

                            Rectangle {
                                id: newWorkspaceButton

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: monitorGroup.group.name === root.shownOn
                                width: 30
                                height: 24
                                radius: root.appearance.radius
                                color: newWorkspaceHover.hovered
                                    ? theme.surfaceHover : theme.backgroundSecondary

                                HoverHandler {
                                    id: newWorkspaceHover
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: theme.accent
                                    font.pixelSize: root.appearance.textSize + 2
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.createWorkspace()
                                }
                            }
                        }

                        Grid {
                            columns: monitorGroup.group.columns
                            spacing: 10

                            Repeater {
                                model: monitorGroup.group.workspaces

                                delegate: Rectangle {
                                    id: workspaceTile

                                    required property var modelData
                                    readonly property int workspaceId: modelData
                                    readonly property bool active: root.workspaceService.isActive(workspaceId)
                                    readonly property bool selected: root.selectedWorkspaceId === workspaceId
                                    readonly property var windows: root.workspaceService
                                        .toplevelsForWorkspace(workspaceId)
                                    // The window entries that fit below the title,
                                    // leaving one for the "+N more" if some don't.
                                    readonly property int entryRoom: Math.max(0, Math.floor((height - 46) / 30))
                                    readonly property int entries: windows.length > entryRoom
                                        ? Math.max(0, entryRoom - 1) : windows.length

                                    width: monitorGroup.group.tileWidth
                                    height: overview.fit.tileHeight
                                    clip: true
                                    radius: root.appearance.radius
                                    color: selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                                        theme.accent.b, 0.2) : active ? theme.surfaceHover
                                            : theme.backgroundSecondary
                                    border.color: selected ? theme.accent : active ? theme.border : "transparent"
                                    border.width: selected || active ? 1 : 0

                                    Behavior on color {
                                        ColorAnimation { duration: root.appearance.motion.short }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.selectedWorkspaceId = workspaceTile.workspaceId;
                                            root.workspaceService.switchTo(workspaceTile.workspaceId);
                                            root.close();
                                        }
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
                                                text: "ACTIVE"
                                                visible: workspaceTile.active
                                                color: theme.accent
                                                font.pixelSize: root.appearance.textSize - 4
                                                font.bold: true
                                            }
                                        }

                                        Repeater {
                                            model: workspaceTile.windows.slice(0, workspaceTile.entries)

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
                                                height: 24
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
                                                    source: IconSource.forName(windowEntry.appClass)
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

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.workspaceService.focusToplevel(windowEntry.toplevel);
                                                        root.close();
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            visible: workspaceTile.windows.length > workspaceTile.entries
                                            text: "+" + (workspaceTile.windows.length - workspaceTile.entries) + " more"
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
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: overview.padding / 2
                text: "Arrows select · Enter focus · N new"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 3
            }
        }
    }
}
