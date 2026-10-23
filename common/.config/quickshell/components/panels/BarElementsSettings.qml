import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import QtQuick
import QtQuick.Controls

Column {
    id: root

    property var appearance
    property string expandedWidget: ""
    readonly property var barElements: BarProfileModel.normalizeBarElements(appearance.barElements)
    readonly property var zones: [{
        "label": "LEFT",
        "short": "L",
        "value": "left"
    }, {
        "label": "CENTER",
        "short": "C",
        "value": "center"
    }, {
        "label": "RIGHT",
        "short": "R",
        "value": "right"
    }]

    function labelFor(element) {
        const labels = {
            "arch": "ARCH ICON",
            "systemMonitor": "SYSTEM MONITOR",
            "currentApp": "CURRENT APP",
            "workspaces": "WORKSPACES",
            "notifications": "NOTIFICATIONS",
            "recording": "SCREEN RECORDING",
            "media": "MEDIA",
            "audio": "AUDIO",
            "bluetooth": "BLUETOOTH",
            "tray": "SYSTEM TRAY",
            "network": "NETWORK",
            "battery": "BATTERY",
            "clock": "CLOCK & POMODORO"
        };
        return labels[element] || element.toUpperCase();
    }

    // Element options, shown next to the element they belong to.
    function optionsFor(element) {
        const options = {
            "workspaces": [{
                "label": "HIDE EMPTY WORKSPACES",
                "propertyName": "hideEmptyWorkspaces"
            }, {
                "label": "SHOW WORKSPACE APP COUNTS",
                "propertyName": "workspaceAppCountVisible"
            }],
            "notifications": [{
                "label": "SHOW UNREAD BADGE",
                "propertyName": "notificationBadgeVisible"
            }],
            "media": [{
                "label": "SHOW TRACK TITLE",
                "propertyName": "mediaTitleVisible"
            }],
            "audio": [{
                "label": "SHOW VOLUME METER",
                "propertyName": "audioMeterVisible"
            }],
            "battery": [{
                "label": "SHOW PERCENTAGE",
                "propertyName": "batteryPercentageVisible"
            }]
        };
        return options[element] || [];
    }

    function toggleWidgetOption(propertyName) {
        appearance[propertyName] = appearance[propertyName] === false;
    }

    width: parent ? parent.width : 0
    spacing: 8

    Config.Theme {
        id: theme
    }

    Text {
        text: "ELEMENTS"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 6
    }

    Text {
        width: root.width
        text: "Every piece of the bar. Turn it on or off, pick its zone (L/C/R) and order it within the zone. Join joins an element with the one above it: joined elements form a group with one shared background."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Repeater {
        model: root.zones

        delegate: Column {
            id: zoneDelegate

            required property var modelData
            readonly property var elements: root.barElements[modelData.value] || []

            width: root.width
            spacing: 4

            Text {
                text: zoneDelegate.modelData.label
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 3
                font.bold: true
                topPadding: 4
            }

            Text {
                visible: zoneDelegate.elements.length === 0
                text: "No elements"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize - 2
            }

            Repeater {
                model: zoneDelegate.elements

                delegate: Column {
                    id: elementDelegate

                    required property var modelData
                    required property int index
                    readonly property string element: modelData.id
                    readonly property bool elementOn: modelData.enabled !== false
                    readonly property var options: root.optionsFor(element)

                    width: root.width
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: root.appearance.radius
                        color: rowHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                        HoverHandler {
                            id: rowHover
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.labelFor(elementDelegate.element)
                                + (elementDelegate.options.length === 0 ? ""
                                    : root.expandedWidget === elementDelegate.element ? " 󰅀" : " 󰅂")
                            color: elementDelegate.elementOn ? theme.text : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 1
                            font.bold: true

                            TapHandler {
                                enabled: elementDelegate.options.length > 0
                                onTapped: root.expandedWidget = root.expandedWidget === elementDelegate.element
                                    ? "" : elementDelegate.element
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            // "Join previous": shares one background with the element above.
                            Rectangle {
                                readonly property bool joined: elementDelegate.modelData.joinPrevious === true

                                visible: elementDelegate.index > 0
                                width: 56
                                height: 30
                                radius: root.appearance.radius
                                color: joined ? theme.accent : joinHover.hovered ? theme.surfaceHover : theme.surface

                                HoverHandler {
                                    id: joinHover
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰌷 Join"
                                    color: parent.joined ? theme.background : theme.textMuted
                                    font.pixelSize: root.appearance.textSize - 3
                                    font.bold: true
                                }

                                TapHandler {
                                    onTapped: root.appearance.setBarElementJoined(elementDelegate.element,
                                        !parent.joined)
                                }

                            }

                            Row {
                                spacing: 2

                                Repeater {
                                    model: root.zones

                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property bool selected: zoneDelegate.modelData.value === modelData.value

                                        width: 26
                                        height: 30
                                        radius: root.appearance.radius
                                        color: selected ? theme.accent : theme.surface

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.modelData.short
                                            color: parent.selected ? theme.background : theme.textMuted
                                            font.pixelSize: root.appearance.textSize - 3
                                            font.bold: true
                                        }

                                        TapHandler {
                                            onTapped: root.appearance.moveBarElementToZone(elementDelegate.element,
                                                parent.modelData.value)
                                        }

                                    }

                                }

                            }

                            Repeater {
                                model: [{
                                    "label": "▲",
                                    "offset": -1
                                }, {
                                    "label": "▼",
                                    "offset": 1
                                }]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool movable: modelData.offset < 0
                                        ? elementDelegate.index > 0
                                        : elementDelegate.index < zoneDelegate.elements.length - 1

                                    width: 30
                                    height: 30
                                    radius: root.appearance.radius
                                    color: moveHover.hovered && movable ? theme.surfaceHover : theme.surface

                                    HoverHandler {
                                        id: moveHover
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData.label
                                        color: parent.movable ? theme.accent : theme.textMuted
                                        font.pixelSize: root.appearance.textSize - 3
                                        font.bold: true
                                    }

                                    TapHandler {
                                        onTapped: root.appearance.moveBarElement(elementDelegate.element,
                                            parent.modelData.offset)
                                    }

                                }

                            }

                            Rectangle {
                                width: 36
                                height: 30
                                radius: root.appearance.radius
                                color: elementDelegate.elementOn ? theme.accent : theme.surface

                                Text {
                                    anchors.centerIn: parent
                                    text: elementDelegate.elementOn ? "On" : "Off"
                                    color: elementDelegate.elementOn ? theme.background : theme.textMuted
                                    font.pixelSize: root.appearance.textSize - 3
                                    font.bold: true
                                }

                                TapHandler {
                                    onTapped: root.appearance.setBarElementEnabled(elementDelegate.element,
                                        !elementDelegate.elementOn)
                                }

                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: root.expandedWidget === elementDelegate.element
                            ? elementDelegate.options.length * 38 + 16 : 0
                        visible: height > 0
                        radius: root.appearance.radius
                        color: theme.surface
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Repeater {
                                model: elementDelegate.options

                                delegate: Rectangle {
                                    required property var modelData

                                    width: parent.width
                                    height: 34
                                    radius: root.appearance.radius
                                    color: optionHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

                                    HoverHandler {
                                        id: optionHover
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.modelData.label
                                        color: theme.text
                                        font.pixelSize: root.appearance.textSize - 2
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.appearance[parent.modelData.propertyName] !== false ? "On" : "Off"
                                        color: root.appearance[parent.modelData.propertyName] !== false
                                            ? theme.accent : theme.textMuted
                                        font.pixelSize: root.appearance.textSize - 2
                                        font.bold: true
                                    }

                                    TapHandler {
                                        onTapped: root.toggleWidgetOption(parent.modelData.propertyName)
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
