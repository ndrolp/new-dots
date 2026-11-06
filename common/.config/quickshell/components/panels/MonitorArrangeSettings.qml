import QtQuick
import "." as Panels
import "../../services/MonitorSetup.js" as MonitorSetup

// The Displays section: the monitors to arrange, and the selected one's controls followed by its
// workspace and bar settings. Every change goes through the service, which applies it and starts the
// Keep or Revert countdown. A monitor that is off or mirroring has no place on the canvas, so the list
// above it is how to reach one.
Column {
    id: root

    required property var appearance
    // Config.Monitors: this monitor's workspace and bar settings.
    property var monitors
    // Services.MonitorSetups.
    property var setups
    property string selectedPort: ""

    readonly property var entries: setups ? setups.entries : []
    readonly property var selected: entries.filter(entry => entry.port === selectedPort)[0] || entries[0] || null
    readonly property var selectedModes: selected !== null ? setups.modesOf(selected.port) : []

    // A monitor's number: the one Identify flashes on it.
    function numberOf(entry) {
        return entries.findIndex(candidate => candidate.port === entry.port) + 1;
    }

    function change(next) {
        root.setups.apply(next);
    }

    width: parent ? parent.width : 0
    spacing: 16

    Item {
        width: parent.width
        height: identifyButton.height

        Panels.SettingsChoiceList {
            anchors.left: parent.left
            anchors.right: identifyButton.left
            anchors.rightMargin: 12
            appearance: root.appearance
            options: root.entries.map(entry => ({
                label: root.numberOf(entry) + " " + entry.description, value: entry.port
            }))
            value: root.selected !== null ? root.selected.port : ""
            onChosen: port => root.selectedPort = port
        }

        Panels.SettingsButton {
            id: identifyButton

            anchors.right: parent.right
            appearance: root.appearance
            label: "Identify"
            onActivated: root.setups.identify()
        }
    }

    Panels.MonitorArrangeCanvas {
        width: parent.width
        appearance: root.appearance
        selectedId: root.selected !== null ? root.selected.port : ""
        monitors: MonitorSetup.rectangles(root.entries).map(rect => {
            const entry = root.entries.filter(candidate => candidate.port === rect.id)[0];
            return Object.assign({ number: root.numberOf(entry), label: entry.description }, rect);
        })
        onSelected: id => root.selectedPort = id
        onDropped: (id, x, y) => root.change(MonitorSetup.moved(root.entries, id, x, y))
    }

    Panels.MonitorControls {
        width: parent.width
        visible: root.selected !== null
        appearance: root.appearance
        entry: root.selected
        modes: root.selectedModes
        canTurnOff: root.selected !== null && MonitorSetup.canTurnOff(root.entries, root.selected.port)
        onOnOffAsked: {
            const port = root.selected.port;
            root.change(root.selected.disabled
                ? MonitorSetup.turnedOn(root.entries, port, root.selectedModes)
                : MonitorSetup.turnedOff(root.entries, port));
        }
        onResolutionChosen: (width, height) => root.change(MonitorSetup.withResolution(root.entries,
            root.selected.port, root.selectedModes, width, height))
        onRefreshChosen: refresh => root.change(MonitorSetup.withRefresh(root.entries, root.selected.port, refresh))
        onScaleChosen: scale => root.change(MonitorSetup.withScale(root.entries, root.selected.port, scale))
        onRotationChosen: transform => root.change(MonitorSetup.withRotation(root.entries, root.selected.port,
            transform))
    }

    Panels.MonitorDisplaySettings {
        width: parent.width
        visible: root.selected !== null
        appearance: root.appearance
        monitors: root.monitors
        monitorDescription: root.selected !== null ? root.selected.description : ""
    }
}
