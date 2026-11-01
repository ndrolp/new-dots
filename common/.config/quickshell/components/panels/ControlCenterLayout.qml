import QtQuick
import "../../config" as Config
import "." as Panels
import "ControlCenterNames.js" as Names

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
// Above everything, in both stages, sit the ongoing notifications
// (`ongoing`: the media card and the `resident` notifications).
// Switching stages or subpages while open fades out what is shown first,
// then fades in the new contents (`shownExpanded`, `shownSubpage` lag behind
// `expanded` and `subpage` until the fade-out ends); opening shows the
// requested stage at once, and so does reduce motion.
Column {
    id: root

    required property var appearance
    // Whether the control center is open; each opening takes `requestedStage`.
    property bool open: false
    property bool controlsEnabled: true
    property string requestedStage: Names.controlCenter.collapsed
    property string stage: Names.controlCenter.collapsed
    readonly property bool expanded: controlsEnabled && stage === Names.controlCenter.expanded
    // The tiles and the rest of the controls; they read `expanded` to show
    // the tile row or everything.
    property Component controls: null
    property Component notifications: null
    // The notifications list, once loaded (it always is): the ongoing
    // notifications read its highlighting.
    readonly property var notificationsItem: notificationsLoader.item
    // The audio output subpage: the outputs, with a back arrow.
    property Component audioOutputs: null
    // The ongoing notifications, on top in both stages; they take no room
    // while their height is 0.
    property Component ongoing: null
    // The open subpage, Names.controlCenter.noSubpage for none.
    property string subpage: Names.controlCenter.noSubpage
    readonly property bool subpageOpen: expanded && subpage !== Names.controlCenter.noSubpage
    // What is on screen: `expanded` and `subpage` once the fade-out between
    // them has ended. The controls read `shownExpanded`.
    property bool shownExpanded: expanded
    property string shownSubpage: subpage
    readonly property bool shownSubpageOpen: shownExpanded
        && shownSubpage !== Names.controlCenter.noSubpage
    // The stage's contents fade through 0 while it switches.
    property real stageOpacity: 1

    // How far the handle is dragged before it switches stages.
    readonly property int dragThreshold: 24

    spacing: 8

    onOpenChanged: {
        if (open) {
            stage = requestedStage;
            subpage = Names.controlCenter.noSubpage;
            showNow();
        }
    }

    // Shows the current stage and subpage, with no fade.
    function showNow() {
        stageFade.stop();
        shownExpanded = expanded;
        shownSubpage = subpage;
        stageOpacity = 1;
    }

    // Fades from what is shown to the current stage and subpage.
    function switchShown() {
        if (shownExpanded === expanded && shownSubpage === subpage && !stageFade.running)
            return;
        if (!open || appearance.motion.brief === 0)
            showNow();
        else
            stageFade.restart();
    }

    onSubpageChanged: switchShown()

    SequentialAnimation {
        id: stageFade

        NumberAnimation {
            target: root
            property: "stageOpacity"
            to: 0
            duration: root.appearance.motion.brief
            easing.type: root.appearance.motion.easing
        }

        ScriptAction {
            script: {
                root.shownExpanded = root.expanded;
                root.shownSubpage = root.subpage;
            }
        }

        NumberAnimation {
            target: root
            property: "stageOpacity"
            to: 1
            duration: root.appearance.motion.short
            easing.type: root.appearance.motion.easing
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
            subpage = Names.controlCenter.noSubpage;
        switchShown();
    }

    // The audio output tile; in the collapsed row it expands first.
    function openAudioOutputs() {
        if (!controlsEnabled)
            return;
        stage = Names.controlCenter.expanded;
        subpage = Names.controlCenter.audioOutputs;
    }

    // The subpage's back arrow.
    function back() {
        subpage = Names.controlCenter.noSubpage;
    }

    // The chevron: expand when collapsed, collapse when expanded.
    function toggleStage() {
        if (controlsEnabled)
            stage = expanded ? Names.controlCenter.collapsed : Names.controlCenter.expanded;
    }

    // The handle was dragged `distance` pixels: down expands, up collapses.
    function dragged(distance) {
        if (!controlsEnabled || Math.abs(distance) < dragThreshold)
            return;
        stage = distance > 0 ? Names.controlCenter.expanded : Names.controlCenter.collapsed;
    }

    Config.Theme {
        id: theme
    }

    Loader {
        width: parent.width
        visible: item !== null && item.height > 0
        sourceComponent: root.ongoing
    }

    Loader {
        width: parent.width
        active: root.controlsEnabled
        visible: active && !root.shownSubpageOpen
        opacity: root.stageOpacity
        sourceComponent: root.controls
    }

    Loader {
        width: parent.width
        active: root.shownSubpageOpen && root.shownSubpage === Names.controlCenter.audioOutputs
        visible: active
        opacity: root.stageOpacity
        sourceComponent: root.audioOutputs
    }

    Item {
        id: handle

        objectName: "stageHandle"
        width: parent.width
        height: 22
        visible: root.controlsEnabled && !root.shownSubpageOpen
        opacity: root.stageOpacity

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
        id: notificationsLoader

        width: parent.width
        visible: !root.shownExpanded
        opacity: root.stageOpacity
        sourceComponent: root.notifications
    }
}
