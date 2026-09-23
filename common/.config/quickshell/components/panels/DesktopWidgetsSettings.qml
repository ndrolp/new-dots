import QtQuick
import QtQuick.Controls
import "../../config" as Config

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    readonly property var defaultWidgetOrder: ["media", "system", "calendar", "network", "weather"]
    readonly property var widgetOrder: {
        const savedOrder = appearance.desktopWidgetOrder || [];
        const order = [];

        for (let index = 0; index < savedOrder.length; index++) {
            const widget = savedOrder[index];
            if (defaultWidgetOrder.indexOf(widget) !== -1 && order.indexOf(widget) === -1)
                order.push(widget);
        }

        for (let index = 0; index < defaultWidgetOrder.length; index++) {
            const widget = defaultWidgetOrder[index];
            if (order.indexOf(widget) === -1)
                order.push(widget);
        }

        return order;
    }

    function labelForWidget(widget) {
        return widget.toUpperCase();
    }

    function moveWidget(widget, offset) {
        const order = widgetOrder.slice();
        const from = order.indexOf(widget);
        const to = from + offset;

        if (from < 0 || to < 0 || to >= order.length)
            return;

        order.splice(from, 1);
        order.splice(to, 0, widget);
        appearance.desktopWidgetOrder = order;
    }

    Config.Theme {
        id: theme
    }

    component WidgetToggle: Rectangle {
        required property string label
        required property string propertyName

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
            color: root.appearance[parent.propertyName] ? theme.accent : theme.surface

            Rectangle {
                x: root.appearance[parent.parent.propertyName] ? parent.width - width - 3 : 3
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
            onTapped: root.appearance[parent.propertyName]
                = !root.appearance[parent.propertyName]
        }
    }

    component PositionSelector: Rectangle {
        required property string label
        required property string propertyName

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
                    if (model[index].value === root.appearance[parent.propertyName])
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

            onActivated: root.appearance[parent.propertyName] = model[index].value
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

    Text {
        text: "Enable a widget, then choose where it appears on the desktop."
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

    WidgetToggle { label: "MEDIA"; propertyName: "desktopMediaEnabled" }
    PositionSelector { label: "MEDIA POSITION"; propertyName: "desktopMediaPosition" }
    WidgetToggle { label: "SYSTEM"; propertyName: "desktopSystemEnabled" }
    PositionSelector { label: "SYSTEM POSITION"; propertyName: "desktopSystemPosition" }
    WidgetToggle { label: "CALENDAR"; propertyName: "desktopCalendarEnabled" }
    PositionSelector { label: "CALENDAR POSITION"; propertyName: "desktopCalendarPosition" }
    WidgetToggle { label: "NETWORK"; propertyName: "desktopNetworkEnabled" }
    PositionSelector { label: "NETWORK POSITION"; propertyName: "desktopNetworkPosition" }
    WidgetToggle { label: "WEATHER"; propertyName: "desktopWeatherEnabled" }
    PositionSelector { label: "WEATHER POSITION"; propertyName: "desktopWeatherPosition" }
}
