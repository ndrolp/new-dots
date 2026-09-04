import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import "../../config" as Config

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

        screen: modelData
        visible: root.open && focusedMonitor
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
            focus: selector.visible

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

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 680)
            height: content.implicitHeight + 32
            radius: 12
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.88)
            border.color: theme.border
            border.width: 1

            Column {
                id: content

                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    text: "AUDIO OUTPUT"
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }

                ListView {
                    id: sinkList

                    width: parent.width
                    height: Math.min(contentHeight, 276)
                    spacing: 4
                    clip: true
                    model: selector.sinks
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: height - 52

                    delegate: Rectangle {
                        id: sinkTile

                        required property var modelData
                        readonly property var sink: modelData
                        readonly property bool selected: ListView.isCurrentItem
                        readonly property bool active: Pipewire.defaultAudioSink === sink

                        width: sinkList.width
                        height: 52
                        radius: 8
                        color: selected || sinkHover.hovered ? theme.surfaceHover : "transparent"
                        border.color: active ? theme.accent : "transparent"
                        border.width: active ? 1 : 0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: selector.sinkIcon(sinkTile.sink)
                                color: sinkTile.active ? theme.accent : theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: 18
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 58
                                text: sinkTile.sink.description || sinkTile.sink.name
                                color: theme.text
                                elide: Text.ElideRight
                                font.family: theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰄬"
                                visible: sinkTile.active
                                color: theme.accent
                                font.pixelSize: 16
                            }
                        }

                        HoverHandler {
                            id: sinkHover
                        }

                        TapHandler {
                            onTapped: {
                                sinkList.currentIndex = index;
                                selector.applyCurrent();
                            }
                        }
                    }
                }

                Text {
                    visible: selector.sinks.length === 0
                    text: "No audio outputs found"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: 12
                }

                Text {
                    visible: selector.sinks.length > 0
                    text: "󰄬 active · H / L or arrows · Enter to apply"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
}
