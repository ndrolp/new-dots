import QtQuick
import "." as Panels

// The desktop widgets of one monitor: each one turned on or off with a switch
// row, its placement a segmented choice and its other settings two per line.
Column {
    id: root

    property var appearance
    property var monitors
    property string monitorName: ""

    readonly property var desktop: monitors.desktopWidgetsFor(monitorName)

    width: parent ? parent.width : 0
    spacing: 14

    function setWidget(widget, key, value) {
        monitors.setDesktopWidgetSetting(monitorName, widget, key, value);
    }

    // Where a desktop widget sits on the monitor, as two segmented choices: the
    // row (top, center, bottom) and the column (left, center, right). The
    // stored position joins them, "top-left", "center-right"…, and is just
    // "center" when both are.
    component Placement: Row {
        id: placement

        required property string widget
        readonly property var parts: {
            const position = root.desktop[widget].position;
            return position === "center" ? ["center", "center"] : position.split("-");
        }
        readonly property alias vertical: verticalChoice
        readonly property alias horizontal: horizontalChoice

        spacing: 8

        function place(vertical, horizontal) {
            root.setWidget(widget, "position", vertical === "center" && horizontal === "center"
                ? "center" : vertical + "-" + horizontal);
        }

        Panels.SettingsChoice {
            id: verticalChoice

            width: (placement.width - placement.spacing) / 2
            anchors.verticalCenter: parent.verticalCenter
            appearance: root.appearance
            options: [
                { label: "Top", value: "top" },
                { label: "Center", value: "center" },
                { label: "Bottom", value: "bottom" }
            ]
            value: placement.parts[0]
            onChosen: vertical => placement.place(vertical, placement.parts[1])
        }

        Panels.SettingsChoice {
            id: horizontalChoice

            width: (placement.width - placement.spacing) / 2
            anchors.verticalCenter: parent.verticalCenter
            appearance: root.appearance
            options: [
                { label: "Left", value: "left" },
                { label: "Center", value: "center" },
                { label: "Right", value: "right" }
            ]
            value: placement.parts[1]
            onChosen: horizontal => placement.place(placement.parts[0], horizontal)
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Widgets"
        topPadding: 8
    }

    Repeater {
        model: [
            { label: "Media", widget: "media" },
            { label: "System", widget: "system" },
            { label: "Calendar", widget: "calendar" },
            { label: "Network", widget: "network" },
            { label: "Weather", widget: "weather" }
        ]

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
                height: 40
                widget: widgetGrid.modelData.widget
            }
        }
    }
}
