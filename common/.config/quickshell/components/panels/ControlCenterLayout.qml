import QtQuick
import "../../config" as Config
import "." as Panels

// The control center's two stages. Collapsed shows the tile row above the
// notifications; expanded shows every control in place of them. Whatever
// opens it asks for a stage (`requestedStage`): the bell and SUPER+N ask for
// "collapsed", SUPER+C for "expanded"; a new request while it is open
// switches it in place. The handle under the controls switches stages: tap
// its chevron, or drag it down to expand and up to collapse. With the
// control center plugin off (`controlsEnabled` false) it is notifications
// only: no controls, no handle, never expanded.
// The audio output tile opens a subpage (`subpage` "audioOutputs") in place
// of the controls, expanding first when it sits in the collapsed row; its
// back arrow (`back()`) returns to the expanded stage. Each opening, and
// collapsing, leaves it.
Column {
    id: root

    required property var appearance
    // Whether the control center is open; each opening takes `requestedStage`.
    property bool open: false
    property bool controlsEnabled: true
    property string requestedStage: "collapsed"
    property string stage: "collapsed"
    readonly property bool expanded: controlsEnabled && stage === "expanded"
    // The tiles and the rest of the controls; they read `expanded` to show
    // the tile row or everything.
    property Component controls: null
    property Component notifications: null
    // The audio output subpage: the outputs, with a back arrow.
    property Component audioOutputs: null
    // The open subpage, "" for none.
    property string subpage: ""
    readonly property bool subpageOpen: expanded && subpage !== ""

    // How far the handle is dragged before it switches stages.
    readonly property int dragThreshold: 24

    spacing: 8

    onOpenChanged: {
        if (open) {
            stage = requestedStage;
            subpage = "";
        }
    }

    // SUPER+C / SUPER+N while it is open: it switches in place.
    onRequestedStageChanged: {
        if (open)
            stage = requestedStage;
    }

    // Collapsing leaves the subpage.
    onExpandedChanged: {
        if (!expanded)
            subpage = "";
    }

    // The audio output tile; in the collapsed row it expands first.
    function openAudioOutputs() {
        if (!controlsEnabled)
            return;
        stage = "expanded";
        subpage = "audioOutputs";
    }

    // The subpage's back arrow.
    function back() {
        subpage = "";
    }

    // The chevron: expand when collapsed, collapse when expanded.
    function toggleStage() {
        if (controlsEnabled)
            stage = expanded ? "collapsed" : "expanded";
    }

    // The handle was dragged `distance` pixels: down expands, up collapses.
    function dragged(distance) {
        if (!controlsEnabled || Math.abs(distance) < dragThreshold)
            return;
        stage = distance > 0 ? "expanded" : "collapsed";
    }

    Config.Theme {
        id: theme
    }

    Loader {
        width: parent.width
        active: root.controlsEnabled
        visible: active && !root.subpageOpen
        sourceComponent: root.controls
    }

    Loader {
        width: parent.width
        active: root.subpageOpen && root.subpage === "audioOutputs"
        visible: active
        sourceComponent: root.audioOutputs
    }

    Item {
        id: handle

        objectName: "stageHandle"
        width: parent.width
        height: 22
        visible: root.controlsEnabled && !root.subpageOpen

        Rectangle {
            anchors.centerIn: parent
            width: 36
            height: 4
            radius: 2
            color: handleArea.containsMouse ? theme.accent : theme.textMuted
            opacity: 0.6
            visible: !chevron.visible
        }

        Panels.Text {
            id: chevron

            anchors.centerIn: parent
            visible: handleArea.containsMouse
            text: root.expanded ? "󰅃" : "󰅀"
            color: theme.accent
            font.pixelSize: root.appearance.textSize + 3
        }

        // A tap is the chevron; a longer move is a drag.
        MouseArea {
            id: handleArea

            property real pressY: 0

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => pressY = mouse.y
            onReleased: mouse => {
                const distance = mouse.y - pressY;
                if (Math.abs(distance) < root.dragThreshold)
                    root.toggleStage();
                else
                    root.dragged(distance);
            }
        }
    }

    Loader {
        width: parent.width
        visible: !root.expanded
        sourceComponent: root.notifications
    }
}
