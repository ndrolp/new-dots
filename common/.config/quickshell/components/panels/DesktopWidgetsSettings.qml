import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import "../../config" as Config

Column {
    id: root

    property var appearance
    property var monitors

    width: parent ? parent.width : 0
    spacing: 12

    readonly property var connectedMonitors: Hyprland.monitors.values
    property string selectedMonitor: ""
    readonly property var desktop: monitors.desktopWidgetsFor(selectedMonitor)
    readonly property var widgetOrder: monitors.desktopWidgetOrder(selectedMonitor)

    function labelForWidget(widget) {
        return widget.toUpperCase();
    }

    function moveWidget(widget, offset) {
        monitors.moveDesktopWidget(selectedMonitor, widget, offset);
    }

    function setWidget(widget, key, value) {
        monitors.setDesktopWidgetSetting(selectedMonitor, widget, key, value);
    }

    function connectedMonitorNames() {
        const names = [];

        for (let index = 0; index < connectedMonitors.length; index++) {
            if (connectedMonitors[index].description !== "")
                names.push(connectedMonitors[index].description);
        }

        return names;
    }

    function ensureSelectedMonitor() {
        const names = connectedMonitorNames();

        if (names.indexOf(selectedMonitor) === -1)
            selectedMonitor = names.length > 0 ? names[0] : "default";
    }

    Component.onCompleted: ensureSelectedMonitor()

    Connections {
        target: Hyprland.monitors

        function onValuesChanged() {
            root.ensureSelectedMonitor();
        }
    }

    Config.Theme {
        id: theme
    }

    component WidgetToggle: Rectangle {
        required property string label
        required property string widget
        property string key: "enabled"
        readonly property bool checked: root.desktop[widget][key]

        width: root.width
        height: 44
        radius: root.appearance.radius
        color: toggleHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: toggleHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 28
            radius: root.appearance.radius
            color: parent.checked ? theme.accent : theme.surface

            Rectangle {
                x: parent.parent.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: theme.text

                Behavior on x {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        TapHandler {
            onTapped: root.setWidget(parent.widget, parent.key, !parent.checked)
        }
    }

    component PositionSelector: Rectangle {
        required property string label
        required property string widget

        width: root.width
        height: 44
        radius: root.appearance.radius
        color: positionHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: positionHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: selector

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            height: 32
            textRole: "label"
            model: [
                { label: "Top left", value: "top-left" },
                { label: "Top center", value: "top-center" },
                { label: "Top right", value: "top-right" },
                { label: "Center left", value: "center-left" },
                { label: "Center", value: "center" },
                { label: "Center right", value: "center-right" },
                { label: "Bottom left", value: "bottom-left" },
                { label: "Bottom center", value: "bottom-center" },
                { label: "Bottom right", value: "bottom-right" }
            ]
            currentIndex: {
                for (let index = 0; index < model.length; index++) {
                    if (model[index].value === root.desktop[parent.widget].position)
                        return index;
                }

                return 4;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: selector.displayText
                color: theme.accent
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            indicator: Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: theme.accent
                font.pixelSize: root.appearance.textSize - 1
            }

            background: Rectangle {
                radius: root.appearance.radius
                color: theme.surface
            }

            onActivated: root.setWidget(parent.widget, "position", model[index].value)
        }
    }

    component WidgetOrderRow: Rectangle {
        id: orderRow

        required property string widget
        required property int orderIndex

        width: root.width
        height: 40
        radius: root.appearance.radius
        color: theme.backgroundSecondary

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: (parent.orderIndex + 1) + ".  " + root.labelForWidget(parent.widget)
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Rectangle {
                width: 30
                height: 28
                radius: root.appearance.radius
                color: upHover.hovered && orderRow.orderIndex > 0 ? theme.surfaceHover : theme.surface
                opacity: orderRow.orderIndex > 0 ? 1 : 0.45

                HoverHandler {
                    id: upHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Up"
                    color: theme.accent
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                TapHandler {
                    enabled: orderRow.orderIndex > 0
                    onTapped: root.moveWidget(orderRow.widget, -1)
                }
            }

            Rectangle {
                width: 42
                height: 28
                radius: root.appearance.radius
                color: downHover.hovered && orderRow.orderIndex < root.widgetOrder.length - 1
                    ? theme.surfaceHover : theme.surface
                opacity: orderRow.orderIndex < root.widgetOrder.length - 1 ? 1 : 0.45

                HoverHandler {
                    id: downHover
                }

                Text {
                    anchors.centerIn: parent
                    text: "Down"
                    color: theme.accent
                    font.pixelSize: root.appearance.textSize - 3
                    font.bold: true
                }

                TapHandler {
                    enabled: orderRow.orderIndex < root.widgetOrder.length - 1
                    onTapped: root.moveWidget(orderRow.widget, 1)
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 6

        Repeater {
            model: root.connectedMonitors

            delegate: Rectangle {
                required property var modelData
                readonly property string monitorDescription: modelData.description

                width: tabLabel.implicitWidth + 20
                height: 30
                radius: root.appearance.radius
                visible: monitorDescription !== ""
                color: root.selectedMonitor === monitorDescription
                    ? theme.accent : tabHover.hovered
                        ? theme.surfaceHover : theme.backgroundSecondary

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                HoverHandler {
                    id: tabHover
                }

                Text {
                    id: tabLabel

                    anchors.centerIn: parent
                    text: "󰍹 " + parent.monitorDescription
                    color: root.selectedMonitor === parent.monitorDescription
                        ? theme.background : theme.text
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }

                TapHandler {
                    onTapped: root.selectedMonitor = parent.monitorDescription
                }
            }
        }
    }

    Text {
        text: "Enable a widget, then choose where it appears on this monitor's desktop."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Text {
        text: "STACK ORDER"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
    }

    Text {
        text: "Sets top-to-bottom order when widgets share a position."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Repeater {
        model: root.widgetOrder

        delegate: WidgetOrderRow {
            required property string modelData

            widget: modelData
            orderIndex: index
        }
    }

    Text {
        text: "BACKGROUND CLOCK"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 8
    }

    WidgetToggle { label: "BACKGROUND CLOCK"; widget: "backgroundClock" }
    PositionSelector { label: "CLOCK POSITION"; widget: "backgroundClock" }
    WidgetToggle { label: "CLOCK CALENDAR"; widget: "backgroundClock"; key: "calendarEnabled" }

    Repeater {
        model: [
            { label: "Clock size", from: 48, to: 160, key: "size" },
            { label: "Clock opacity", from: 20, to: 100, key: "opacity" }
        ]

        delegate: Column {
            required property var modelData

            width: root.width
            spacing: 5

            Text {
                text: modelData.label.toUpperCase()
                color: theme.textMuted
                font.pixelSize: 11
                font.bold: true
            }

            SettingsInput {
                width: parent.width
                appearance: root.appearance
                text: String(root.desktop.backgroundClock[modelData.key])
                validator: IntValidator {
                    bottom: modelData.from
                    top: modelData.to
                }
                onEditingFinished: root.setWidget("backgroundClock", modelData.key, Number(text))
            }

            SettingsSlider {
                width: parent.width
                from: modelData.from
                to: modelData.to
                stepSize: 1
                value: root.desktop.backgroundClock[modelData.key]
                onMoved: root.setWidget("backgroundClock", modelData.key, Math.round(value))
            }
        }
    }

    Rectangle {
        width: root.width
        height: 44
        radius: root.appearance.radius
        color: dateFormatHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: dateFormatHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "CLOCK DATE FORMAT"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: dateFormatSelector

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 168
            height: 32
            textRole: "label"
            model: [
                { label: "Full date", value: "full" },
                { label: "Short date", value: "short" },
                { label: "Numeric date", value: "numeric" },
                { label: "Hidden", value: "none" }
            ]
            currentIndex: {
                for (let index = 0; index < model.length; index++) {
                    if (model[index].value === root.desktop.backgroundClock.dateFormat)
                        return index;
                }

                return 0;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: dateFormatSelector.displayText
                color: theme.accent
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            indicator: Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: theme.accent
                font.pixelSize: root.appearance.textSize - 1
            }

            background: Rectangle {
                radius: root.appearance.radius
                color: theme.surface
            }

            onActivated: root.setWidget("backgroundClock", "dateFormat", model[index].value)
        }
    }

    Text {
        text: "WIDGETS"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 8
    }

    WidgetToggle { label: "MEDIA"; widget: "media" }
    PositionSelector { label: "MEDIA POSITION"; widget: "media" }
    WidgetToggle { label: "SYSTEM"; widget: "system" }
    PositionSelector { label: "SYSTEM POSITION"; widget: "system" }
    WidgetToggle { label: "CALENDAR"; widget: "calendar" }
    PositionSelector { label: "CALENDAR POSITION"; widget: "calendar" }
    WidgetToggle { label: "NETWORK"; widget: "network" }
    PositionSelector { label: "NETWORK POSITION"; widget: "network" }
    WidgetToggle { label: "WEATHER"; widget: "weather" }
    PositionSelector { label: "WEATHER POSITION"; widget: "weather" }

    Column {
        width: root.width
        spacing: 5

        Text {
            text: "WEATHER LOCATION"
            color: theme.textMuted
            font.pixelSize: 11
            font.bold: true
        }

        SettingsInput {
            width: parent.width
            appearance: root.appearance
            text: root.desktop.weather.location
            onEditingFinished: root.setWidget("weather", "location", text.trim())
        }
    }
}
