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

    // The windows a workspace's tile shows. These are the toplevels themselves
    // rather than copies, so a refresh leaves each window's item in place.
    function windowsOn(id) {
        const focused = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;

        return Hyprland.toplevels.values.filter(toplevel => toplevel.address !== ""
            && WorkspaceOverview.isShownOn(toplevel.lastIpcObject, id, focused));
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
        const monitor = groups.find(group => group.name === shownOn);
        const id = monitor === undefined ? null : monitor.newWorkspace;

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

        WindowFrames {
            id: windowFrames

            windows: overview.shown ? Hyprland.toplevels.values : []
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

        // A drag doesn't go on over a window that closed, nor after the overview did.
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
                    else if (event.key === Qt.Key_Escape && windowDrag.dragging)
                        windowDrag.cancel();
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
                        required property int index
                        readonly property var group: modelData
                        // The real monitor behind this group of tiles.
                        readonly property var area: root.groups[index]

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

                                    width: monitorGroup.group.tileWidth
                                    height: overview.fit.tileHeight
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
                                            root.selectedWorkspaceId = workspaceTile.workspaceId;
                                            root.workspaceService.switchTo(workspaceTile.workspaceId);
                                            root.close();
                                        }
                                    }

                                    WindowDropTarget {
                                        id: windowDrop

                                        anchors.fill: parent
                                        accepts: window => WorkspaceOverview.movesTo(
                                            window.lastIpcObject, workspaceTile.workspaceId)
                                        onWindowDropped: window => root.workspaceService.moveToWorkspace(
                                            window, workspaceTile.workspaceId)
                                    }

                                    Item {
                                        anchors.fill: parent

                                        Repeater {
                                            id: windowItems

                                            model: ScriptModel {
                                                values: root.windowsOn(workspaceTile.workspaceId)
                                            }

                                            delegate: Rectangle {
                                                id: windowItem

                                                required property var modelData
                                                readonly property var toplevel: modelData
                                                readonly property var details: toplevel.lastIpcObject
                                                readonly property var box: WorkspaceOverview.miniature(
                                                    details, monitorGroup.area, workspaceTile)
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

                                                // A MouseArea so a click here doesn't reach the tile below.
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
                                        text: "󰍹  " + workspaceTile.workspaceId
                                        color: workspaceTile.selected ? theme.accent : theme.text
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
                                        visible: workspaceTile.active
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

                            NewWorkspaceTile {
                                visible: monitorGroup.group.newWorkspace !== null
                                width: monitorGroup.group.tileWidth
                                height: overview.fit.tileHeight
                                appearance: root.appearance
                                colors: theme
                                workspace: monitorGroup.group.newWorkspace ?? -1
                                onWindowDropped: window => root.workspaceService.moveToNewWorkspace(
                                    window, workspace, monitorGroup.group.name)
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
