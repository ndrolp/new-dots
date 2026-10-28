import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import "../../config" as Config
import "." as Panels

Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()
    signal sinkSelected(var sink)

    model: Quickshell.screens

    delegate: PanelWindow {
        id: selector

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property var sinks: Pipewire.nodes.values.filter(node => node.isSink)
        // Open on the focused monitor; the window stays up while it fades out.
        readonly property bool shown: root.open && focusedMonitor

        screen: modelData
        visible: surface.reveal > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-audio-sink-selector"
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

        PwObjectTracker {
            objects: Pipewire.nodes.values
        }

        function close() {
            root.closeRequested();
        }

        function sinkIcon(sink) {
            const description = String(sink.description || "").toLowerCase();

            if (description.includes("headphone") || description.includes("headset"))
                return "󰋋";
            if (description.includes("hdmi") || description.includes("displayport"))
                return "󰍹";
            if (description.includes("bluetooth"))
                return "󰂯";
            return "󰓃";
        }

        function selectRelative(offset) {
            if (sinks.length === 0)
                return;

            sinkList.currentIndex = (sinkList.currentIndex + offset + sinks.length) % sinks.length;
            sinkList.positionViewAtIndex(sinkList.currentIndex, ListView.Contain);
        }

        function applyCurrent() {
            if (!sinkList.currentItem)
                return;

            Pipewire.preferredDefaultAudioSink = sinkList.currentItem.sink;
            root.sinkSelected(sinkList.currentItem.sink);
            close();
        }

        onVisibleChanged: {
            if (!visible)
                return;

            sinkList.currentIndex = Math.max(0, sinks.indexOf(Pipewire.defaultAudioSink));
            selectorFocus.forceActiveFocus();
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: selector.close()
            }
        }

        Item {
            id: selectorFocus

            anchors.fill: parent
            focus: selector.shown

            Keys.onEscapePressed: selector.close()
            Keys.onLeftPressed: selector.selectRelative(-1)
            Keys.onRightPressed: selector.selectRelative(1)
            Keys.onUpPressed: selector.selectRelative(-1)
            Keys.onDownPressed: selector.selectRelative(1)
            Keys.onReturnPressed: selector.applyCurrent()
            Keys.onEnterPressed: selector.applyCurrent()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_H || event.key === Qt.Key_K) {
                    selector.selectRelative(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_L || event.key === Qt.Key_J) {
                    selector.selectRelative(1);
                    event.accepted = true;
                }
            }
        }

        PopupSurface {
            id: surface

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 440)
            height: implicitHeight
            open: selector.shown
            enabled: selector.shown
            radius: root.appearance.radius
            motion: root.appearance.motion
            motionEasing: root.appearance.motionEasing

            Column {
                width: parent.width
                spacing: 10

                PopupHeader {
                    appearance: root.appearance
                    icon: "󰓃"
                    title: "Audio output"
                    subtitle: selector.sinks.length > 0
                        ? "󰄬 active · H / L or arrows · Enter to apply"
                        : "No audio outputs found"
                }

                ListView {
                    id: sinkList

                    width: parent.width
                    height: Math.min(contentHeight, 276)
                    visible: count > 0
                    spacing: 2
                    clip: true
                    model: selector.sinks
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height - 36

                    delegate: PopupRow {
                        id: sinkTile

                        required property var modelData
                        required property int index
                        readonly property var sink: modelData
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property bool active: Pipewire.defaultAudioSink === sink

                        appearance: root.appearance
                        width: sinkList.width
                        height: outputName.rowHeight
                        color: selected || hovered ? theme.surfaceHover : "transparent"

                        Panels.Text {
                            id: sinkIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: selector.sinkIcon(sinkTile.sink)
                            color: sinkTile.active ? theme.accent : theme.textMuted
                            font.pixelSize: root.appearance.textSize + 3
                        }

                        Panels.AudioOutputName {
                            id: outputName

                            anchors.left: sinkIcon.right
                            anchors.leftMargin: 10
                            anchors.right: activeMark.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            appearance: root.appearance
                            output: sinkTile.sink
                            highlighted: sinkTile.active
                        }

                        Panels.Text {
                            id: activeMark

                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰄬"
                            visible: sinkTile.active
                            color: theme.accent
                            font.pixelSize: root.appearance.textSize + 1
                        }

                        TapHandler {
                            onTapped: {
                                sinkList.currentIndex = sinkTile.index;
                                selector.applyCurrent();
                            }
                        }
                    }
                }
            }
        }
    }
}
