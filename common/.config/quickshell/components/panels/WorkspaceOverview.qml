import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
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
    readonly property var listedMonitors: WorkspaceOverview.monitorsWithWorkspaces(
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

    function goTo(id) {
        selectedWorkspaceId = id;
        workspaceService.switchTo(id);
        close();
    }

    // Does what keyAction named. `placed` is the layout's monitors.
    function act(action, placed) {
        if (action === "create") {
            createWorkspace();
        } else if (action === "close") {
            close();
        } else if (action === "activate") {
            if (selectedWorkspaceId >= 1)
                goTo(selectedWorkspaceId);
        } else {
            selectedWorkspaceId = WorkspaceOverview.selectionAfter(action, placed, selectedWorkspaceId);
        }
    }

    function createWorkspace() {
        const monitor = listedMonitors.find(listed => listed.name === shownOn);

        if (monitor === undefined || !WorkspaceOverview.hasSlot(monitor))
            return;

        selectedWorkspaceId = monitor.newWorkspace;
        workspaceService.createWorkspace(monitor.newWorkspace, shownOn);
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
        id: screenWindow

        required property var modelData
        readonly property bool shown: root.shownOn === modelData.name
        property real reveal: shown ? 1 : 0

        readonly property int padding: 40
        readonly property int hintHeight: 24
        readonly property var arrangement: WorkspaceOverview.layout(
            root.listedMonitors,
            width - padding * 2,
            height - padding * 2 - hintHeight,
            WorkspaceOverview.spacing,
            height / 3
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

        WindowFrames {
            id: windowFrames

            // Until it has faded out, so its thumbnails last through the fade.
            windows: screenWindow.visible ? Hyprland.toplevels.values : []
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

        // A window's place comes from lastIpcObject, which Hyprland only fills
        // in when asked: any event while this is up asks again, a burst once.
        Connections {
            target: Hyprland
            enabled: screenWindow.shown

            function onRawEvent() {
                windowRefresh.start();
            }
        }

        // A drag doesn't go on over a window that closed, nor after the workspace
        // overview did.
        Connections {
            target: Hyprland.toplevels
            enabled: windowDrag.window !== null

            function onValuesChanged() {
                if (Hyprland.toplevels.values.indexOf(windowDrag.window) === -1)
                    windowDrag.cancel();
            }
        }

        onShownChanged: {
            if (!shown)
                windowDrag.cancel();
        }

        Timer {
            id: windowRefresh

            interval: 30
            onTriggered: Hyprland.refreshToplevels()
        }

        Item {
            anchors.fill: parent
            opacity: screenWindow.reveal

            Rectangle {
                anchors.fill: parent
                enabled: screenWindow.shown
                color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.85)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            FocusScope {
                id: keyboardFocus

                anchors.fill: parent
                focus: screenWindow.visible

                Keys.onPressed: event => {
                    const action = screenWindow.shown
                        ? WorkspaceOverview.keyAction(event.key, windowDrag.dragging) : null;

                    event.accepted = action !== null;

                    if (action === "cancelDrag")
                        windowDrag.cancel();
                    else if (action !== null)
                        root.act(action, screenWindow.arrangement.monitors);
                }
            }

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -screenWindow.hintHeight / 2
                enabled: screenWindow.shown
                spacing: WorkspaceOverview.spacing.monitor

                Repeater {
                    // Only the screen it's on builds its miniatures.
                    model: screenWindow.visible ? screenWindow.arrangement.monitors : []

                    delegate: Column {
                        id: monitorColumn

                        required property var modelData
                        readonly property var monitor: modelData.monitor

                        width: modelData.width

                        WorkspaceMonitorHeader {
                            width: parent.width
                            appearance: root.appearance
                            monitorName: monitorColumn.monitor.name
                            canAddWorkspace: monitorColumn.monitor.name === root.shownOn
                                && WorkspaceOverview.hasSlot(monitorColumn.monitor)
                            onAddWorkspaceRequested: root.createWorkspace()
                        }

                        Grid {
                            columns: monitorColumn.modelData.columns
                            spacing: WorkspaceOverview.spacing.miniature

                            Repeater {
                                model: monitorColumn.monitor.workspaces

                                delegate: WorkspaceMiniature {
                                    required property var modelData

                                    workspace: modelData
                                    width: monitorColumn.modelData.miniatureWidth
                                    height: screenWindow.arrangement.miniatureHeight
                                    appearance: root.appearance
                                    workspaceService: root.workspaceService
                                    monitor: monitorColumn.monitor
                                    frames: windowFrames
                                    drag: windowDrag
                                    selected: root.selectedWorkspaceId === workspace
                                    onClicked: root.goTo(workspace)
                                    onWindowDropped: window => root.workspaceService.moveToWorkspace(
                                        window, workspace, monitorColumn.monitor.name)
                                }
                            }

                            Repeater {
                                model: WorkspaceOverview.hasSlot(monitorColumn.monitor)
                                    ? [monitorColumn.monitor.newWorkspace] : []

                                delegate: NewWorkspaceSlot {
                                    required property var modelData

                                    workspace: modelData
                                    width: monitorColumn.modelData.miniatureWidth
                                    height: screenWindow.arrangement.miniatureHeight
                                    appearance: root.appearance
                                    onWindowDropped: window => root.workspaceService.moveToWorkspace(
                                        window, workspace, monitorColumn.monitor.name)
                                }
                            }
                        }
                    }
                }
            }

            WindowDrag {
                id: windowDrag

                anchors.fill: parent
                enabled: screenWindow.shown
                ghost: Component {
                    WindowDragGhost {
                        appearance: root.appearance
                        frames: windowFrames
                        window: windowDrag.window
                    }
                }
                onClicked: window => {
                    root.workspaceService.focusToplevel(window);
                    root.close();
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: screenWindow.padding / 2
                text: "Arrows select · Enter focus · N new"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 3
            }
        }
    }
}
