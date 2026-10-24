import QtQuick
import "." as Panels
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel

// The Bar section's bar elements list: every bar element of the edited bar
// profile, zone by zone, in full width rows that stay transparent until
// hovered. A row turns its element on or off, picks its zone, orders it and
// joins it with the one above; elements with options open them below as
// switch rows.
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
            "recording": "Screen recording",
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

    // Element options, shown under the element they belong to.
    function optionsFor(element) {
        const options = {
            "workspaces": [
                { label: "Hide empty workspaces", option: "hideEmpty" },
                { label: "Show workspace app counts", option: "appCountVisible" }
            ],
            "notifications": [{ label: "Show unread badge", option: "badgeVisible" }],
            "media": [{ label: "Show track title", option: "titleVisible" }],
            "audio": [{ label: "Show volume meter", option: "meterVisible" }],
            "battery": [{ label: "Show percentage", option: "percentageVisible" }]
        };
        return (options[element] || []).map(entry => Object.assign({ "element": element }, entry));
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

                    // The element's options, two per line, indented under it.
                    Panels.SettingsGrid {
                        visible: elementDelegate.expanded
                        x: 24
                        width: parent.width - x
                        columnSpacing: 12
                        rowSpacing: 2

                        Repeater {
                            model: elementDelegate.options

                            delegate: Panels.SettingsSwitchRow {
                                required property var modelData

                                width: parent.cellWidth
                                appearance: root.appearance
                                label: modelData.label
                                checked: root.appearance.barElementOption(modelData.element, modelData.option)
                                onToggled: root.toggleElementOption(modelData.element, modelData.option)
                            }
                        }
                    }
                }
            }
        }
    }
}
