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

    // Numbered groups still only join former status modules.
    function groupable(element) {
        return ["arch", "systemMonitor", "currentApp", "workspaces"].indexOf(element) === -1;
    }

    function setGroup(module, group) {
        const values = Object.assign({
        }, appearance.statusModuleGroups || {
        });
        if (group === 0)
            delete values[module];
        else
            values[module] = group;
        appearance.statusModuleGroups = values;
    }

    function toggleWidgetOption(propertyName) {
        appearance[propertyName] = appearance[propertyName] === false;
    }

    width: parent ? parent.width : 0
    spacing: 8

    Config.Theme {
        id: theme
    }

    Rectangle {
        width: root.width
        height: 44
        radius: root.appearance.radius
        color: profileHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            HoverHandler {
                id: profileHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "PROFILE CONTENT"
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ComboBox {
                    id: profileSelector

                    width: 132
                    height: 32
                    textRole: "label"
                    model: [{
                        "label": "Minimal",
                        "value": "minimal"
                    }, {
                        "label": "Work",
                        "value": "work"
                    }, {
                        "label": "Media",
                        "value": "media"
                    }, {
                        "label": "Presentation",
                        "value": "presentation"
                    }]
                    currentIndex: {
                        for (let index = 0; index < model.length; index++) {
                            if (model[index].value === root.appearance.activeBarProfile)
                                return index;

                        }
                        return 1;
                    }
                    onActivated: root.appearance.applyBarProfile(model[index].value)

                    contentItem: Text {
                        leftPadding: 10
                        rightPadding: 8
                        verticalAlignment: Text.AlignVCenter
                        text: profileSelector.displayText
                        color: theme.accent
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 1
                        font.bold: true
                    }

                    indicator: Item {
                    }

                    background: Rectangle {
                        radius: root.appearance.radius
                        color: theme.surface
                    }

                }

                Rectangle {
                    width: 48
                    height: 32
                    radius: root.appearance.radius
                    color: saveHover.hovered ? theme.accentHover : theme.accent

                    HoverHandler {
                        id: saveHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: theme.background
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: root.appearance.saveBarProfile(profileSelector.model[profileSelector.currentIndex].value)
                    }

                }

            }

        }

        Text {
            text: "Choose a profile, then save its visible bar data, placement, grouping, and order."
            color: theme.textMuted
            font.pixelSize: root.appearance.textSize - 1
            wrapMode: Text.Wrap
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
            text: "Every piece of the bar. Turn it on or off, pick its zone (L/C/R) and order it within the zone. Elements in the same group share one background surface."
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

                            ComboBox {
                                id: groupSelector

                                visible: root.groupable(elementDelegate.element)
                                width: 82
                                height: 32
                                textRole: "label"
                                model: [{
                                    "label": "Separate",
                                    "value": 0
                                }, {
                                    "label": "Group 1",
                                    "value": 1
                                }, {
                                    "label": "Group 2",
                                    "value": 2
                                }, {
                                    "label": "Group 3",
                                    "value": 3
                                }]
                                currentIndex: (root.appearance.statusModuleGroups || {
                                })[elementDelegate.element] || 0
                                onActivated: root.setGroup(elementDelegate.element, model[index].value)

                                contentItem: Text {
                                    leftPadding: 8
                                    rightPadding: 6
                                    verticalAlignment: Text.AlignVCenter
                                    text: groupSelector.displayText
                                    color: theme.accent
                                    elide: Text.ElideRight
                                    font.pixelSize: root.appearance.textSize - 3
                                    font.bold: true
                                }

                                indicator: Item {
                                }

                                background: Rectangle {
                                    radius: root.appearance.radius
                                    color: theme.surface
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
