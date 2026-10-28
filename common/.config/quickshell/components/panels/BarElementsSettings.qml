import QtQuick
import "." as Panels
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel

// The Bar section's bar elements list: every bar element of the edited bar
// profile, zone by zone, in full width rows that stay transparent until
// hovered. A row turns its element on or off, picks its zone, orders it and
// joins it with the one above; elements with options open them below:
// switches, numbers and choices.
Column {
    id: root

    required property var appearance
    property string expandedElement: ""
    readonly property var barElements: BarProfileModel.normalizeBarElements(appearance.barElements)
    readonly property var zones: [
        { label: "Left", short: "L", value: "left" },
        { label: "Center", short: "C", value: "center" },
        { label: "Right", short: "R", value: "right" }
    ]

    function labelFor(element) {
        const labels = {
            "arch": "Arch icon",
            "systemMonitor": "System monitor",
            "currentApp": "Current app",
            "workspaces": "Workspaces",
            "notifications": "Notifications",
            "recording": "Recording indicator",
            "media": "Media",
            "cava": "Cava",
            "audio": "Audio",
            "bluetooth": "Bluetooth",
            "tray": "System tray",
            "network": "Network",
            "battery": "Battery",
            "clock": "Clock & pomodoro"
        };
        return labels[element] || element;
    }

    // Element options, shown under the element they belong to, each edited
    // as `optionField` says: a switch, a number or a choice.
    property var elementOptions: ({
        "workspaces": [
            { label: "Hide empty workspaces", option: "hideEmpty" },
            { label: "Show workspace app counts", option: "appCountVisible" }
        ],
        "notifications": [{ label: "Show unread badge", option: "badgeVisible" }],
        "media": [{ label: "Show track title", option: "titleVisible" }],
        "cava": [
            { label: "Bars", option: "barCount" },
            { label: "Bar width", option: "barWidth" },
            { label: "Color", option: "color" }
        ],
        "audio": [{ label: "Show volume meter", option: "meterVisible" }],
        "battery": [{ label: "Show percentage", option: "percentageVisible" }]
    })

    // How an option is edited ({ kind: "switch" }, { kind: "number", from, to }
    // or { kind: "choice", choices: [{ label, value }] }); the model's, which
    // also keeps saved values within those limits.
    property var optionField: BarProfileModel.elementOptionField

    // A hint shown under an enabled element while there is something to say
    // about it, e.g. { "cava": "cava isn't installed…" }; empty shows nothing.
    property var elementHints: ({})

    function optionsFor(element) {
        return (elementOptions[element] || []).map(entry => Object.assign({ "element": element },
            optionField(element, entry.option), entry));
    }

    function toggleElementOption(element, option) {
        appearance.setBarElementOption(element, option, !appearance.barElementOption(element, option));
    }

    width: parent ? parent.width : 0
    spacing: 6

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Elements"
        topPadding: 8
    }

    Panels.SettingsHint {
        width: root.width
        appearance: root.appearance
        text: "Every piece of the bar. Turn it on or off, pick its zone (L/C/R) and order it within the zone. Join joins an element with the one above it: joined elements form a group with one shared background."
    }

    Repeater {
        model: root.zones

        delegate: Column {
            id: zoneDelegate

            required property var modelData
            readonly property var elements: root.barElements[modelData.value] || []

            width: root.width
            spacing: 2

            Panels.SettingsHeading {
                appearance: root.appearance
                text: zoneDelegate.modelData.label
                topPadding: 10
                bottomPadding: 2
            }

            Panels.SettingsHint {
                visible: zoneDelegate.elements.length === 0
                appearance: root.appearance
                text: "No elements"
                leftPadding: 12
            }

            Repeater {
                model: zoneDelegate.elements

                delegate: Column {
                    id: elementDelegate

                    required property var modelData
                    required property int index
                    readonly property string element: modelData.id
                    readonly property bool elementOn: modelData.enabled !== false
                    readonly property bool joined: modelData.joinPrevious === true
                    readonly property var options: root.optionsFor(element)
                    readonly property bool expanded: root.expandedElement === element

                    width: root.width
                    spacing: 2

                    Panels.SettingsRow {
                        id: elementRow

                        readonly property string elementLabel: root.labelFor(elementDelegate.element)

                        width: parent.width
                        height: 40
                        appearance: root.appearance

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Panels.SettingsLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                appearance: root.appearance
                                text: elementRow.elementLabel
                                color: elementDelegate.elementOn ? theme.text : theme.textMuted

                                TapHandler {
                                    enabled: elementDelegate.options.length > 0
                                    onTapped: root.expandedElement = elementDelegate.expanded
                                        ? "" : elementDelegate.element
                                }
                            }

                            Panels.SettingsHint {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: elementDelegate.options.length > 0
                                appearance: root.appearance
                                text: elementDelegate.expanded ? "󰅀" : "󰅂"
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            // Join: shares one background with the element above.
                            Panels.SettingsButton {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: elementDelegate.index > 0
                                appearance: root.appearance
                                label: "󰌷  Join"
                                labelColor: elementDelegate.joined ? theme.accent : theme.textMuted
                                onActivated: root.appearance.setBarElementJoined(elementDelegate.element,
                                    !elementDelegate.joined)
                            }

                            Panels.SettingsChoice {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 96
                                appearance: root.appearance
                                options: root.zones.map(zone => ({ label: zone.short, value: zone.value }))
                                value: zoneDelegate.modelData.value
                                onChosen: zone => root.appearance.moveBarElementToZone(elementDelegate.element, zone)
                            }

                            Panels.SettingsMoveButtons {
                                anchors.verticalCenter: parent.verticalCenter
                                appearance: root.appearance
                                canMoveUp: elementDelegate.index > 0
                                canMoveDown: elementDelegate.index < zoneDelegate.elements.length - 1
                                onMovedUp: root.appearance.moveBarElement(elementDelegate.element, -1)
                                onMovedDown: root.appearance.moveBarElement(elementDelegate.element, 1)
                            }

                            Item {
                                width: 8
                                height: 1
                            }

                            Panels.SettingsSwitch {
                                anchors.verticalCenter: parent.verticalCenter
                                checked: elementDelegate.elementOn

                                TapHandler {
                                    onTapped: root.appearance.setBarElementEnabled(elementDelegate.element,
                                        !elementDelegate.elementOn)
                                }
                            }
                        }
                    }

                    Panels.SettingsHint {
                        readonly property string hint: root.elementHints[elementDelegate.element] || ""

                        visible: hint !== "" && elementDelegate.elementOn
                        x: 24
                        width: parent.width - x
                        appearance: root.appearance
                        text: hint
                        leftPadding: 12
                    }

                    // The element's options, two per line, indented under it.
                    Panels.SettingsGrid {
                        visible: elementDelegate.expanded
                        x: 24
                        width: parent.width - x
                        columnSpacing: 12
                        rowSpacing: 2

                        Repeater {
                            model: elementDelegate.options

                            delegate: Loader {
                                id: optionCell

                                required property var modelData
                                readonly property var value: root.appearance.barElementOption(
                                    modelData.element, modelData.option)

                                // The model keeps what is saved within the option's limits.
                                function save(value) {
                                    root.appearance.setBarElementOption(modelData.element, modelData.option, value);
                                }

                                width: parent.cellWidth
                                sourceComponent: modelData.kind === "switch" ? switchOption : fieldOption

                                Component {
                                    id: switchOption

                                    Panels.SettingsSwitchRow {
                                        appearance: root.appearance
                                        label: optionCell.modelData.label
                                        checked: optionCell.value
                                        onToggled: root.toggleElementOption(optionCell.modelData.element,
                                            optionCell.modelData.option)
                                    }
                                }

                                // A number or a choice, its label lined up with the switches'.
                                Component {
                                    id: fieldOption

                                    Item {
                                        height: field.height + 8

                                        Loader {
                                            id: field

                                            x: 12
                                            y: 4
                                            width: parent.width - 24
                                            sourceComponent: optionCell.modelData.kind === "number"
                                                ? numberOption : choiceOption
                                        }
                                    }
                                }

                                Component {
                                    id: numberOption

                                    Panels.SettingsNumber {
                                        appearance: root.appearance
                                        label: optionCell.modelData.label
                                        from: optionCell.modelData.from
                                        to: optionCell.modelData.to
                                        value: optionCell.value
                                        onEdited: value => optionCell.save(value)
                                    }
                                }

                                Component {
                                    id: choiceOption

                                    Panels.SettingsField {
                                        appearance: root.appearance
                                        label: optionCell.modelData.label

                                        Panels.SettingsChoice {
                                            width: parent.width
                                            appearance: root.appearance
                                            options: optionCell.modelData.choices
                                            value: optionCell.value
                                            onChosen: value => optionCell.save(value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
