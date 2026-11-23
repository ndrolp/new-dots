import Quickshell.Services.Pipewire
import QtQuick
import "../../config" as Config
import "." as Panels

// The audio output selector: every audio output, the active one marked.
// H/L, J/K or the arrows move, Enter (or a click) makes the selected one the
// active audio output and closes. Shown full-screen (AudioSinkSelector.qml) or
// inside a capsule (AudioSinkSelectorPopup.qml); `active` is true while it is
// shown.
Item {
    id: root

    required property var appearance
    // Shown: becoming true selects the active audio output, with the keys focused.
    property bool active: false
    readonly property var sinks: Pipewire.nodes.values.filter(node => node.isSink)

    signal closeRequested()
    signal sinkSelected(var sink)

    implicitHeight: content.implicitHeight

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

    onActiveChanged: {
        if (!active)
            return;

        sinkList.currentIndex = Math.max(0, sinks.indexOf(Pipewire.defaultAudioSink));
        selectorFocus.forceActiveFocus();
    }

    Item {
        id: selectorFocus

        anchors.fill: parent
        focus: root.active

        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.selectRelative(-1)
        Keys.onRightPressed: root.selectRelative(1)
        Keys.onUpPressed: root.selectRelative(-1)
        Keys.onDownPressed: root.selectRelative(1)
        Keys.onReturnPressed: root.applyCurrent()
        Keys.onEnterPressed: root.applyCurrent()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_H || event.key === Qt.Key_K) {
                root.selectRelative(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_L || event.key === Qt.Key_J) {
                root.selectRelative(1);
                event.accepted = true;
            }
        }
    }

    Column {
        id: content

        width: parent.width
        spacing: 10

        PopupHeader {
            appearance: root.appearance
            icon: "󰓃"
            title: "Audio output"
            subtitle: root.sinks.length > 0
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
            model: root.sinks
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

                Panels.ShellText {
                    id: sinkIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sinkIcon(sinkTile.sink)
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

                Panels.ShellText {
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
                        root.applyCurrent();
                    }
                }
            }
        }
    }
}
