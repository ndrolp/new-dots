import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../config" as Config
import "../IconSource.js" as IconSource

Variants {
    id: root

    required property var appearance
    required property var workspaceService
    property bool open: false
    property string selectedAddress: ""
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

        // One capture per window while open. A window with no frame, which can
        // happen on a hidden workspace, keeps the application icon.
        WindowFrames {
            id: windowFrames

            windows: switcher.visible ? root.windows() : []
        }

        Rectangle {
            id: switcherCard

            readonly property int windowCount: root.windows().length
            readonly property int cardWidth: 260
            readonly property int cardSpacing: 8
            readonly property int padding: 12

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, Math.max(cardWidth, windowCount * cardWidth
                + (windowCount - 1) * cardSpacing) + padding * 2)
            height: 190 + padding * 2
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.92)
            border.color: theme.border
            border.width: 1

            ListView {
                id: windowList

                anchors.fill: parent
                anchors.margins: switcherCard.padding
                orientation: ListView.Horizontal
                clip: true
                spacing: switcherCard.cardSpacing
                model: root.windows()
                currentIndex: root.windows().findIndex(
                    window => window.address === root.selectedAddress)
                highlightMoveDuration: root.appearance.motion.brief
                boundsBehavior: Flickable.StopAtBounds

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: Rectangle {
                    id: windowCard

                    required property var modelData
                    readonly property var toplevel: modelData
                    readonly property bool selected: root.selectedAddress === toplevel.address
                    readonly property var frame: windowFrames.frameOf(toplevel)
                    readonly property string appClass: String(
                        toplevel.lastIpcObject?.class
                            || toplevel.lastIpcObject?.initialClass
                            || "application"
                    ).toLowerCase()

                    width: switcherCard.cardWidth
                    height: windowList.height
                    radius: root.appearance.radius
                    color: selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                        theme.accent.b, 0.2) : cardHover.hovered ? theme.surfaceHover
                            : theme.backgroundSecondary
                    border.color: selected ? theme.accent : "transparent"
                    border.width: selected ? 2 : 0

                    Behavior on color {
                        ColorAnimation { duration: root.appearance.motion.brief }
                    }

                    HoverHandler {
                        id: cardHover
                    }

                    IconImage {
                        id: applicationIcon

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 10
                        width: 20
                        height: 20
                        source: IconSource.forName(windowCard.appClass)
                    }

                    ShellText {
                        anchors.left: applicationIcon.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: applicationIcon.verticalCenter
                        text: windowCard.toplevel.title || windowCard.appClass
                        color: theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: windowCard.selected
                    }

                    Item {
                        id: preview

                        // Fits the frame in the card without stretching it.
                        readonly property real frameScale: windowCard.frame
                            && windowCard.frame.sourceSize.width > 0
                            ? Math.min(width / windowCard.frame.sourceSize.width,
                                height / windowCard.frame.sourceSize.height) : 1

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: applicationIcon.bottom
                        anchors.bottom: parent.bottom
                        anchors.margins: 10

                        IconImage {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            // A translucent window would show it through its frame.
                            visible: !windowCard.frame || !windowCard.frame.hasContent
                            source: IconSource.forName(windowCard.appClass)
                        }

                        WindowThumbnail {
                            anchors.centerIn: parent
                            width: frame ? frame.sourceSize.width * preview.frameScale : 0
                            height: frame ? frame.sourceSize.height * preview.frameScale : 0
                            frame: windowCard.frame
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: workspaceLabel.implicitWidth + 12
                            height: workspaceLabel.implicitHeight + 6
                            radius: root.appearance.radius
                            color: theme.surface

                            ShellText {
                                id: workspaceLabel

                                anchors.centerIn: parent
                                text: "󰍹 " + windowCard.toplevel.workspace.id
                                color: windowCard.selected ? theme.accent : theme.textMuted
                                font.pixelSize: root.appearance.textSize - 3
                                font.bold: true
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            root.selectedAddress = windowCard.toplevel.address;
                            root.activateSelected(true);
                        }
                    }
                }
            }

            ShellText {
                anchors.centerIn: parent
                visible: switcherCard.windowCount === 0
                text: "No switchable windows"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize
            }
        }
    }
}
