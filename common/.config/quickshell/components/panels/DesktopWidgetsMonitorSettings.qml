import QtQuick
import "." as Panels
import "../../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// The desktop widgets of one monitor: each one turned on or off with a switch
// row, its placement a segmented choice and its other settings two per line.
Column {
    id: root

    required property var appearance
    property var monitors
    property string monitorName: ""

    readonly property var desktop: monitors.desktopWidgetsFor(monitorName)
    readonly property var widgetOrder: monitors.desktopWidgetOrder(monitorName)
    readonly property var widgetLabels: ({
        media: "Media", system: "System", calendar: "Calendar", network: "Network", weather: "Weather",
        cava: "Cava"
    })
    // The glyph before each desktop widget's settings.
    readonly property var widgetIcons: ({
        media: "󰝚", system: "󰻠", calendar: "󰃭", network: "󰤨",
        weather: "󰖐", cava: ""
    })

    width: parent ? parent.width : 0
    spacing: 14

    function setWidget(widget, key, value) {
        monitors.setDesktopWidgetSetting(monitorName, widget, key, value);
    }

    // Where a desktop widget sits on the monitor, under its label, as two
    // segmented choices: the row (top, center, bottom) and the column (left,
    // center, right).
    component Placement: Panels.SettingsField {
        id: placement

        required property string widget
        readonly property var parts: DesktopWidgetsModel.placementOf(root.desktop[widget].position)
        readonly property alias vertical: verticalChoice
        readonly property alias horizontal: horizontalChoice

        appearance: root.appearance

        function place(vertical, horizontal) {
            root.setWidget(widget, "position", DesktopWidgetsModel.positionOf(vertical, horizontal));
        }

        Row {
            width: parent.width
            spacing: 8

            Panels.SettingsChoice {
                id: verticalChoice

                width: (parent.width - parent.spacing) / 2
                appearance: root.appearance
                options: [
                    { label: "Top", value: "top" },
                    { label: "Center", value: "center" },
                    { label: "Bottom", value: "bottom" }
                ]
                value: placement.parts.vertical
                onChosen: vertical => placement.place(vertical, placement.parts.horizontal)
            }

            Panels.SettingsChoice {
                id: horizontalChoice

                width: (parent.width - parent.spacing) / 2
                appearance: root.appearance
                options: [
                    { label: "Left", value: "left" },
                    { label: "Center", value: "center" },
                    { label: "Right", value: "right" }
                ]
                value: placement.parts.horizontal
                onChosen: horizontal => placement.place(placement.parts.vertical, horizontal)
            }
        }
    }

    Panels.SettingsGrid {
        id: edgeGrid

        width: root.width

        // How far every desktop widget of this monitor keeps from the edges.
        Panels.SettingsNumber {
            width: edgeGrid.cellWidth
            appearance: root.appearance
            label: "Edge padding"
            icon: "\uf0b2"
            from: DesktopWidgetsModel.edgePaddingRange.from
            to: DesktopWidgetsModel.edgePaddingRange.to
            value: root.desktop.edgePadding
            onEdited: padding => root.monitors.setDesktopWidgetsEdgePadding(root.monitorName, padding)
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Background clock"
        topPadding: 4
    }

    Panels.SettingsGrid {
        id: clockGrid

        width: root.width

        Panels.SettingsSwitchRow {
            width: clockGrid.cellWidth
            appearance: root.appearance
            label: "Background clock"
            icon: "󰥔"
            checked: root.desktop.backgroundClock.enabled
            onToggled: root.setWidget("backgroundClock", "enabled", !root.desktop.backgroundClock.enabled)
        }

        Placement {
            width: clockGrid.cellWidth
            label: "Clock position"
            icon: "󰆾"
            widget: "backgroundClock"
        }

        Repeater {
            model: [
                { label: "Clock size", icon: "", from: 48, to: 160, key: "size" },
                { label: "Clock opacity", icon: "", from: 20, to: 100, key: "opacity" }
            ]

            delegate: Panels.SettingsNumber {
                required property var modelData

                width: clockGrid.cellWidth
                appearance: root.appearance
                label: modelData.label
                icon: modelData.icon
                from: modelData.from
                to: modelData.to
                value: root.desktop.backgroundClock[modelData.key]
                onEdited: number => root.setWidget("backgroundClock", modelData.key, number)
            }
        }

        Panels.SettingsSwitchRow {
            width: clockGrid.cellWidth
            appearance: root.appearance
            label: "Clock calendar"
            icon: "󰃭"
            checked: root.desktop.backgroundClock.calendarEnabled
            onToggled: root.setWidget("backgroundClock", "calendarEnabled",
                !root.desktop.backgroundClock.calendarEnabled)
        }

        Panels.SettingsField {
            width: clockGrid.cellWidth
            appearance: root.appearance
            label: "Date format"
            icon: ""

            Panels.SettingsChoice {
                width: parent.width
                appearance: root.appearance
                options: [
                    { label: "Full", value: "full" },
                    { label: "Short", value: "short" },
                    { label: "Numeric", value: "numeric" },
                    { label: "Hidden", value: "none" }
                ]
                value: root.desktop.backgroundClock.dateFormat
                onChosen: format => root.setWidget("backgroundClock", "dateFormat", format)
            }
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Widgets"
        topPadding: 8
    }

    Repeater {
        model: Object.keys(root.widgetLabels).map(widget => ({ label: root.widgetLabels[widget], widget: widget }))

        delegate: Panels.SettingsGrid {
            id: widgetGrid

            required property var modelData

            width: root.width
            rowSpacing: 4

            Panels.SettingsSwitchRow {
                width: widgetGrid.cellWidth
                appearance: root.appearance
                label: widgetGrid.modelData.label
                icon: root.widgetIcons[widgetGrid.modelData.widget]
                checked: root.desktop[widgetGrid.modelData.widget].enabled
                onToggled: root.setWidget(widgetGrid.modelData.widget, "enabled",
                    !root.desktop[widgetGrid.modelData.widget].enabled)
            }

            Placement {
                width: widgetGrid.cellWidth
                label: widgetGrid.modelData.label + " position"
                icon: "󰆾"
                widget: widgetGrid.modelData.widget
            }

            // The Cava widget's size, bars, color and shadow.
            Repeater {
                model: widgetGrid.modelData.widget === "cava" ? [
                    { label: "Cava width", icon: "", from: 80, to: 1600, key: "width" },
                    { label: "Cava height", icon: "", from: 20, to: 400, key: "height" },
                    { label: "Cava bars", icon: "", from: 8, to: 96, key: "barCount" }
                ] : []

                delegate: Panels.SettingsNumber {
                    required property var modelData

                    width: widgetGrid.cellWidth
                    appearance: root.appearance
                    label: modelData.label
                    icon: modelData.icon
                    from: modelData.from
                    to: modelData.to
                    value: root.desktop.cava[modelData.key]
                    onEdited: number => root.setWidget("cava", modelData.key, number)
                }
            }

            Panels.SettingsField {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "cava"
                appearance: root.appearance
                label: "Cava color"
                icon: ""

                Panels.SettingsChoiceList {
                    width: parent.width
                    appearance: root.appearance
                    options: DesktopWidgetsModel.cavaColors.map(color => ({
                        label: color.charAt(0).toUpperCase() + color.slice(1), value: color
                    }))
                    value: root.desktop.cava.color
                    onChosen: color => root.setWidget("cava", "color", color)
                }
            }

            Panels.SettingsSwitchRow {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "cava"
                appearance: root.appearance
                label: "Cava shadow"
                icon: ""
                checked: root.desktop.cava.shadow
                onToggled: root.setWidget("cava", "shadow", !root.desktop.cava.shadow)
            }

            // What the Cava widget shows of the track that plays.
            Panels.SettingsSwitchRow {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "cava"
                appearance: root.appearance
                label: "Cava media info"
                icon: "󰎈"
                checked: root.desktop.cava.mediaInfo
                onToggled: root.setWidget("cava", "mediaInfo", !root.desktop.cava.mediaInfo)
            }

            Panels.SettingsField {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "cava"
                appearance: root.appearance
                label: "Cava progress"
                icon: ""

                Panels.SettingsChoice {
                    width: parent.width
                    appearance: root.appearance
                    options: DesktopWidgetsModel.cavaProgressStyles.map(style => ({
                        label: style.charAt(0).toUpperCase() + style.slice(1), value: style
                    }))
                    value: root.desktop.cava.progress
                    onChosen: style => root.setWidget("cava", "progress", style)
                }
            }

            Panels.SettingsField {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "cava" && root.desktop.cava.progress !== "off"
                appearance: root.appearance
                label: "Cava progress color"
                icon: ""

                Panels.SettingsChoiceList {
                    width: parent.width
                    appearance: root.appearance
                    options: DesktopWidgetsModel.cavaColors.map(color => ({
                        label: color.charAt(0).toUpperCase() + color.slice(1), value: color
                    }))
                    value: root.desktop.cava.progressColor
                    onChosen: color => root.setWidget("cava", "progressColor", color)
                }
            }

            // The weather widget's location.
            Panels.SettingsField {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "weather"
                appearance: root.appearance
                label: "Location"
                icon: ""

                Panels.SettingsInput {
                    width: parent.width
                    appearance: root.appearance
                    text: root.desktop.weather.location
                    onEdited: text => root.setWidget("weather", "location", text.trim())
                }
            }
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Stack order"
        topPadding: 8
    }

    Panels.SettingsHint {
        width: root.width
        appearance: root.appearance
        text: "Sets top-to-bottom order when widgets share a position."
    }

    Repeater {
        model: root.widgetOrder

        delegate: Item {
            id: orderRow

            required property string modelData
            required property int index
            readonly property bool first: index === 0
            readonly property bool last: index === root.widgetOrder.length - 1

            width: root.width
            height: 36

            Panels.SettingsIcon {
                id: orderIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                appearance: root.appearance
                text: root.widgetIcons[orderRow.modelData]
            }

            Panels.SettingsLabel {
                anchors.left: orderIcon.right
                anchors.leftMargin: 8
                anchors.right: moveButtons.left
                anchors.verticalCenter: parent.verticalCenter
                appearance: root.appearance
                text: (orderRow.index + 1) + ". " + root.widgetLabels[orderRow.modelData]
            }

            Panels.SettingsMoveButtons {
                id: moveButtons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                appearance: root.appearance
                canMoveUp: !orderRow.first
                canMoveDown: !orderRow.last
                onMovedUp: root.monitors.moveDesktopWidget(root.monitorName, orderRow.modelData, -1)
                onMovedDown: root.monitors.moveDesktopWidget(root.monitorName, orderRow.modelData, 1)
            }
        }
    }
}
