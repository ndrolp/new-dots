import QtQuick
import "." as Panels
import "../../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// The desktop widgets of one monitor: each one turned on or off with a switch
// row, its placement a segmented choice and its other settings two per line.
Column {
    id: root

    property var appearance
    property var monitors
    property string monitorName: ""

    readonly property var desktop: monitors.desktopWidgetsFor(monitorName)
    readonly property var widgetOrder: monitors.desktopWidgetOrder(monitorName)
    readonly property var widgetLabels: ({
        media: "Media", system: "System", calendar: "Calendar", network: "Network", weather: "Weather"
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
            checked: root.desktop.backgroundClock.enabled
            onToggled: root.setWidget("backgroundClock", "enabled", !root.desktop.backgroundClock.enabled)
        }

        Placement {
            width: clockGrid.cellWidth
            label: "Clock position"
            widget: "backgroundClock"
        }

        Repeater {
            model: [
                { label: "Clock size", from: 48, to: 160, key: "size" },
                { label: "Clock opacity", from: 20, to: 100, key: "opacity" }
            ]

            delegate: Panels.SettingsNumber {
                required property var modelData

                width: clockGrid.cellWidth
                appearance: root.appearance
                label: modelData.label
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
            checked: root.desktop.backgroundClock.calendarEnabled
            onToggled: root.setWidget("backgroundClock", "calendarEnabled",
                !root.desktop.backgroundClock.calendarEnabled)
        }

        Panels.SettingsField {
            width: clockGrid.cellWidth
            appearance: root.appearance
            label: "Date format"

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
                checked: root.desktop[widgetGrid.modelData.widget].enabled
                onToggled: root.setWidget(widgetGrid.modelData.widget, "enabled",
                    !root.desktop[widgetGrid.modelData.widget].enabled)
            }

            Placement {
                width: widgetGrid.cellWidth
                label: widgetGrid.modelData.label + " position"
                widget: widgetGrid.modelData.widget
            }

            // Only the weather widget has a setting of its own.
            Panels.SettingsField {
                width: widgetGrid.cellWidth
                visible: widgetGrid.modelData.widget === "weather"
                appearance: root.appearance
                label: "Location"

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

            Panels.SettingsLabel {
                anchors.left: parent.left
                anchors.leftMargin: 12
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
