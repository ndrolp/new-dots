import QtQuick
import "." as Panels
import "../../services/MonitorModes.js" as MonitorModes

// The selected monitor's on/off, resolution, refresh rate, scale and rotation. Choosing only asks:
// whoever owns the setup changes it and hands the new `entry` back.
Column {
    id: root

    required property var appearance
    // The monitor's entry in the setup (services/MonitorSetup.js).
    property var entry: null
    // Its modes, as MonitorModes.parsedModes gives them.
    property var modes: []
    property bool canTurnOff: true
    signal onOffAsked()
    signal resolutionChosen(int width, int height)
    signal refreshChosen(real refresh)
    signal scaleChosen(real scale)
    signal rotationChosen(int transform)

    readonly property bool on: entry !== null && !entry.disabled
    readonly property var mode: entry !== null ? MonitorModes.parsedMode(entry.mode) : null
    // The last scale asked for on this monitor, to tell if what applied is a different one.
    property real askedScale: 0
    readonly property bool scaleSnapped: on && askedScale !== 0
        && scaleLabel(askedScale) !== scaleLabel(entry.scale)

    function trimmed(value) {
        return String(Math.round(value * 100) / 100);
    }

    function scaleLabel(scale) {
        return trimmed(scale);
    }

    onEntryChanged: {
        if (entry === null || !on)
            askedScale = 0;
    }

    width: parent ? parent.width : 0
    spacing: 14

    Panels.SettingsSwitchRow {
        width: parent.width
        appearance: root.appearance
        label: "On"
        checked: root.on
        enabled: !root.on || root.canTurnOff
        onToggled: root.onOffAsked()
    }

    Panels.SettingsField {
        width: parent.width
        visible: root.on
        appearance: root.appearance
        label: "Resolution"

        Panels.SettingsChoiceList {
            width: parent.width
            appearance: root.appearance
            options: MonitorModes.resolutions(root.modes).map(resolution => ({
                label: resolution.label, value: resolution.label
            }))
            value: root.mode !== null ? root.mode.width + "x" + root.mode.height : ""
            onChosen: chosen => {
                const size = MonitorModes.parsedMode(chosen);
                root.resolutionChosen(size.width, size.height);
            }
        }
    }

    Panels.SettingsField {
        width: parent.width
        visible: root.on
        appearance: root.appearance
        label: "Refresh rate"

        Panels.SettingsChoiceList {
            width: parent.width
            appearance: root.appearance
            options: root.mode === null ? []
                : MonitorModes.refreshRates(root.modes, root.mode.width, root.mode.height).map(rate => ({
                    label: root.trimmed(rate) + " Hz", value: rate
                }))
            value: root.mode !== null ? root.mode.refresh : 0
            onChosen: chosen => root.refreshChosen(chosen)
        }
    }

    Panels.SettingsField {
        width: parent.width
        visible: root.on
        appearance: root.appearance
        label: "Scale"

        Panels.SettingsChoiceList {
            width: parent.width
            appearance: root.appearance
            options: root.on ? MonitorModes.scaleChoices(root.entry.scale).map(scale => ({
                label: root.scaleLabel(scale), value: scale
            })) : []
            value: root.on ? root.entry.scale : 0
            onChosen: chosen => {
                root.askedScale = chosen;
                root.scaleChosen(chosen);
            }
        }

        Panels.SettingsHint {
            width: parent.width
            visible: root.scaleSnapped
            appearance: root.appearance
            text: root.scaleSnapped ? root.scaleLabel(root.askedScale) + " isn't available at this resolution, so "
                + root.scaleLabel(root.entry.scale) + " was applied." : ""
        }
    }

    Panels.SettingsField {
        width: parent.width
        visible: root.on
        appearance: root.appearance
        label: "Rotation"

        Panels.SettingsChoice {
            width: Math.min(parent.width, 320)
            appearance: root.appearance
            options: [
                { label: "0°", value: 0 },
                { label: "90°", value: 1 },
                { label: "180°", value: 2 },
                { label: "270°", value: 3 }
            ]
            value: root.on ? root.entry.transform : 0
            onChosen: chosen => root.rotationChosen(chosen)
        }
    }
}
