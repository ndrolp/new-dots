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

    function selectRelative(offset) {
        selectedWorkspaceId = WorkspaceOverview.stepped(
            WorkspaceOverview.workspaceIds(listedMonitors), selectedWorkspaceId, offset);
    }

    // Moves a row up or down within the monitor holding the selection.
    function selectRow(direction, fit) {
        const monitor = fit.monitors[WorkspaceOverview.monitorHolding(listedMonitors, selectedWorkspaceId)];

        if (monitor !== undefined) {
            selectedWorkspaceId = WorkspaceOverview.stepped(
                monitor.workspaces, selectedWorkspaceId, direction * monitor.columns);
        }
    }

    function selectEnd(last) {
        const ids = WorkspaceOverview.workspaceIds(listedMonitors);

        selectedWorkspaceId = ids.length > 0 ? ids[last ? ids.length - 1 : 0] : -1;
    }

    function activateSelected() {
        if (selectedWorkspaceId < 1)
            return;

        workspaceService.switchTo(selectedWorkspaceId);
        close();
    }

    // Does what keyAction named.
    function act(action, fit) {
        if (action === "next")
            selectRelative(1);
        else if (action === "previous")
            selectRelative(-1);
        else if (action === "rowDown")
            selectRow(1, fit);
        else if (action === "rowUp")
            selectRow(-1, fit);
        else if (action === "first")
            selectEnd(false);
        else if (action === "last")
            selectEnd(true);
        else if (action === "create")
            createWorkspace();
        else if (action === "activate")
            activateSelected();
        else if (action === "close")
            close();
    }

    function createWorkspace() {
        const monitor = listedMonitors.find(listed => listed.name === shownOn);
        const id = monitor === undefined ? null : monitor.newWorkspace;

        if (id === null)
            return;

        selectedWorkspaceId = id;
        workspaceService.createWorkspace(id, shownOn);
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
            root.listedMonitors,
            width - padding * 2,
            height - padding * 2 - hintHeight,
            {
                miniature: 10,
                monitor: 32,
                header: 30,
                maxMiniatureHeight: height / 3
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

        WindowFrames {
            id: windowFrames

            // Until it has faded out, so its thumbnails last through the fade.
            windows: overview.visible ? Hyprland.toplevels.values : []
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
            enabled: overview.shown

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
                    const action = overview.shown
                        ? WorkspaceOverview.keyAction(event.key, windowDrag.dragging) : null;

                    event.accepted = action !== null;

                    if (action === "cancelDrag")
                        windowDrag.cancel();
                    else if (action !== null)
                        root.act(action, overview.fit);
                }
            }

            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -overview.hintHeight / 2
                enabled: overview.shown
                spacing: 32

                Repeater {
                    // Only the screen it's on builds its miniatures.
                    model: overview.visible ? overview.fit.monitors : []

                    delegate: Column {
                        id: monitorColumn

                        required property var modelData
                        required property int index
                        readonly property var placed: modelData
                        // The real monitor behind these miniatures.
                        readonly property var area: root.listedMonitors[index]

                        width: placed.width

                        WorkspaceMonitorHeader {
                            width: parent.width
                            appearance: root.appearance
                            monitorName: monitorColumn.placed.name
                            canAddWorkspace: monitorColumn.placed.name === root.shownOn
                                && WorkspaceOverview.hasSlot(monitorColumn.placed)
                            onAddWorkspaceRequested: root.createWorkspace()
                        }

                        Grid {
                            columns: monitorColumn.placed.columns
                            spacing: 10

                            Repeater {
                                model: monitorColumn.placed.workspaces

                                delegate: Rectangle {
                                    id: workspaceMiniature

                                    required property var modelData
                                    readonly property int workspaceId: modelData
                                    readonly property bool active: root.workspaceService.isActive(workspaceId)
                                    readonly property bool selected: root.selectedWorkspaceId === workspaceId

                                    width: monitorColumn.placed.miniatureWidth
                                    height: overview.fit.miniatureHeight
                                    clip: true
                                    radius: root.appearance.radius
                                    color: windowDrop.containsDrag ? Qt.rgba(theme.accent.r, theme.accent.g,
                                        theme.accent.b, 0.4) : selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                                        theme.accent.b, 0.2) : active ? theme.surfaceHover
                                            : theme.backgroundSecondary
                                    border.color: windowDrop.containsDrag || selected ? theme.accent
                                        : active ? theme.border : "transparent"
                                    border.width: windowDrop.containsDrag ? 2 : selected || active ? 1 : 0

                                    Behavior on color {
                                        ColorAnimation { duration: root.appearance.motion.short }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.selectedWorkspaceId = workspaceMiniature.workspaceId;
                                            root.workspaceService.switchTo(workspaceMiniature.workspaceId);
                                            root.close();
                                        }
                                    }

                                    WindowDropTarget {
                                        id: windowDrop

                                        anchors.fill: parent
                                        accepts: window => WorkspaceOverview.movesTo(
                                            window.lastIpcObject, workspaceMiniature.workspaceId)
                                        onWindowDropped: window => root.workspaceService.moveToWorkspace(
                                            window, workspaceMiniature.workspaceId, monitorColumn.placed.name)
                                    }

                                    Item {
                                        anchors.fill: parent

                                        Repeater {
                                            id: windowItems

                                            model: ScriptModel {
                                                values: root.workspaceService.windowsOn(workspaceMiniature.workspaceId)
                                            }

                                            delegate: Rectangle {
                                                id: windowItem

                                                required property var modelData
                                                readonly property var toplevel: modelData
                                                readonly property var details: toplevel.lastIpcObject
                                                readonly property var box: WorkspaceOverview.windowBox(
                                                    details, monitorColumn.area, workspaceMiniature)
                                                readonly property string appClass: WorkspaceOverview.appClass(details)

                                                x: box.x
                                                y: box.y
                                                z: WorkspaceOverview.stacking(details)
                                                width: box.width
                                                height: box.height
                                                clip: true
                                                radius: root.appearance.radius / 2
                                                color: windowHover.hovered ? theme.surfaceHover : theme.surface
                                                border.color: theme.border
                                                border.width: 1

                                                HoverHandler {
                                                    id: windowHover
                                                }

                                                IconImage {
                                                    id: windowIcon

                                                    anchors.centerIn: parent
                                                    anchors.verticalCenterOffset: windowTitle.visible ? -10 : 0
                                                    width: Math.max(0, Math.min(24, parent.width - 4, parent.height - 4))
                                                    height: width
                                                    source: IconSource.forName(windowItem.appClass)
                                                }

                                                Text {
                                                    id: windowTitle

                                                    anchors.top: windowIcon.bottom
                                                    anchors.topMargin: 2
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.margins: 4
                                                    visible: parent.height > 48
                                                    text: windowItem.toplevel.title || windowItem.appClass
                                                    color: theme.text
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignHCenter
                                                    font.pixelSize: root.appearance.textSize - 4
                                                }

                                                WindowThumbnail {
                                                    anchors.fill: parent
                                                    anchors.margins: parent.border.width
                                                    frame: windowFrames.frameOf(windowItem.toplevel)
                                                    // The hover colour shows through.
                                                    opacity: windowHover.hovered ? 0.85 : 1
                                                }

                                                // A MouseArea so a click here doesn't reach the miniature below.
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onPressed: windowDrag.press(windowItem.toplevel,
                                                        WorkspaceOverview.canDrag(windowItem.details))
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.margins: 6
                                        text: "󰍹  " + workspaceMiniature.workspaceId
                                        color: workspaceMiniature.selected ? theme.accent : theme.text
                                        style: Text.Outline
                                        styleColor: theme.surface
                                        font.pixelSize: root.appearance.textSize
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 6
                                        text: "ACTIVE"
                                        visible: workspaceMiniature.active
                                        color: theme.accent
                                        style: Text.Outline
                                        styleColor: theme.surface
                                        font.pixelSize: root.appearance.textSize - 4
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: windowItems.count === 0
                                        text: "Empty workspace"
                                        color: theme.textDisabled
                                        font.pixelSize: root.appearance.textSize - 3
                                    }
                                }
                            }

                            NewWorkspaceSlot {
                                visible: WorkspaceOverview.hasSlot(monitorColumn.placed)
                                width: monitorColumn.placed.miniatureWidth
                                height: overview.fit.miniatureHeight
                                appearance: root.appearance
                                colors: theme
                                workspace: monitorColumn.placed.newWorkspace ?? -1
                                onWindowDropped: window => root.workspaceService.moveToWorkspace(
                                    window, workspace, monitorColumn.placed.name)
                            }
                        }
                    }
                }
            }

            WindowDrag {
                id: windowDrag

                anchors.fill: parent
                enabled: overview.shown
                ghost: Component {
                    WindowDragGhost {
                        appearance: root.appearance
                        frames: windowFrames
                        colors: theme
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
                anchors.bottomMargin: overview.padding / 2
                text: "Arrows select · Enter focus · N new"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 3
            }
        }
    }
}
