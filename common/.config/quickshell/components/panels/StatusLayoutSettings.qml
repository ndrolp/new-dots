import QtQuick
import QtQuick.Controls
import "../../config" as Config

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 8

    readonly property var defaultOrder: [
        "notifications", "recording", "media", "audio", "bluetooth", "tray", "network",
        "battery", "clock"
    ]
    readonly property var modules: {
        const savedOrder = appearance.statusModuleOrder || [];
        const order = [];

        for (let index = 0; index < savedOrder.length; index++) {
            const module = savedOrder[index];
            if (defaultOrder.indexOf(module) !== -1 && order.indexOf(module) === -1)
                order.push(module);
        }

        for (let index = 0; index < defaultOrder.length; index++) {
            const module = defaultOrder[index];
            if (order.indexOf(module) === -1)
                order.push(module);
        }

        return order;
    }

    function labelFor(module) {
        const labels = {
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
        return labels[module] || module.toUpperCase();
    }

    function moveModule(module, offset) {
        const order = modules.slice();
        const from = order.indexOf(module);
        const to = from + offset;

        if (from < 0 || to < 0 || to >= order.length)
            return;

        order.splice(from, 1);
        order.splice(to, 0, module);
        appearance.statusModuleOrder = order;
    }

    function setEnabled(module, enabled) {
        const values = Object.assign({}, appearance.statusModuleEnabled || {});
        values[module] = enabled;
        appearance.statusModuleEnabled = values;
    }

    function setGroup(module, group) {
        const values = Object.assign({}, appearance.statusModuleGroups || {});

        if (group === 0)
            delete values[module];
        else
            values[module] = group;

        appearance.statusModuleGroups = values;
    }

    function setPlacement(module, placement) {
        const values = Object.assign({}, appearance.statusModulePlacement || {});

        if (placement === "right")
            delete values[module];
        else
            values[module] = placement;

        appearance.statusModulePlacement = values;
    }

    function setElementEnabled(element, enabled) {
        const values = Object.assign({}, appearance.barElementEnabled || {});
        values[element] = enabled;
        appearance.barElementEnabled = values;
    }

    function setElementPlacement(element, placement) {
        const values = Object.assign({}, appearance.barElementPlacement || {});
        const defaults = {
            "arch": "left",
            "system": "left",
            "currentApp": "left",
            "workspaces": "center"
        };

        if (placement === defaults[element])
            delete values[element];
        else
            values[element] = placement;

        appearance.barElementPlacement = values;
    }

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
                model: [
                    { label: "Minimal", value: "minimal" },
                    { label: "Work", value: "work" },
                    { label: "Media", value: "media" },
                    { label: "Presentation", value: "presentation" }
                ]
                currentIndex: {
                    for (let index = 0; index < model.length; index++) {
                        if (model[index].value === root.appearance.activeBarProfile)
                            return index;
                    }

                    return 1;
                }

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

                indicator: Item {}

                background: Rectangle {
                    radius: root.appearance.radius
                    color: theme.surface
                }

                onActivated: root.appearance.applyBarProfile(model[index].value)
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
                    onTapped: root.appearance.saveBarProfile(profileSelector.model[
                        profileSelector.currentIndex].value)
                }
            }
        }
    }

    Text {
        text: "Choose a profile, then save its visible bar content, placement, grouping, and order."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Text {
        text: "GROUPS"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 6
    }

    Text {
        text: "Modules in the same group share one background surface."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Text {
        text: "BAR ELEMENTS"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 8
    }

    Text {
        text: "Place or hide the Arch icon, hardware monitor, current app, and workspace selector."
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
        wrapMode: Text.Wrap
    }

    Repeater {
        model: [
            { label: "ARCH ICON", value: "arch", defaultPlacement: "left" },
            { label: "HARDWARE INFO", value: "system", defaultPlacement: "left" },
            { label: "CURRENT APP", value: "currentApp", defaultPlacement: "left" },
            { label: "WORKSPACES", value: "workspaces", defaultPlacement: "center" }
        ]

        delegate: Rectangle {
            id: elementRow

            required property var modelData
            readonly property string placement: (root.appearance.barElementPlacement || {})[
                modelData.value] || modelData.defaultPlacement

            width: root.width
            height: 44
            radius: root.appearance.radius
            color: elementHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            HoverHandler {
                id: elementHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.label
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: [
                        { label: "L", value: "left" },
                        { label: "C", value: "center" },
                        { label: "R", value: "right" }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: 28
                        height: 28
                        radius: root.appearance.radius
                        color: elementRow.placement === modelData.value ? theme.accent : theme.surface

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: elementRow.placement === parent.modelData.value
                                ? theme.background : theme.textMuted
                            font.pixelSize: root.appearance.textSize - 3
                            font.bold: true
                        }

                        TapHandler {
                            onTapped: root.setElementPlacement(elementRow.modelData.value,
                                parent.modelData.value)
                        }
                    }
                }

                Rectangle {
                    width: 36
                    height: 28
                    radius: root.appearance.radius
                    color: (root.appearance.barElementEnabled || {})[elementRow.modelData.value] === false
                        ? theme.surface : theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: (root.appearance.barElementEnabled || {})[elementRow.modelData.value] === false
                            ? "Off" : "On"
                        color: (root.appearance.barElementEnabled || {})[elementRow.modelData.value] === false
                            ? theme.textMuted : theme.background
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: root.setElementEnabled(elementRow.modelData.value,
                            (root.appearance.barElementEnabled || {})[elementRow.modelData.value] === false)
                    }
                }
            }
        }
    }

    Repeater {
        model: root.modules

        delegate: Rectangle {
            id: moduleRow

            required property string modelData
            readonly property int moduleIndex: root.modules.indexOf(modelData)

            width: root.width
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
                text: root.labelFor(moduleRow.modelData)
                color: theme.text
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                ComboBox {
                    id: groupSelector

                    width: 82
                    height: 32
                    textRole: "label"
                    model: [
                        { label: "Separate", value: 0 },
                        { label: "Group 1", value: 1 },
                        { label: "Group 2", value: 2 },
                        { label: "Group 3", value: 3 }
                    ]
                    currentIndex: {
                        const group = (root.appearance.statusModuleGroups || {})[moduleRow.modelData] || 0;
                        return group;
                    }

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

                    indicator: Item {}

                    background: Rectangle {
                        radius: root.appearance.radius
                        color: theme.surface
                    }

                    onActivated: root.setGroup(moduleRow.modelData, model[index].value)
                }

                Row {
                    spacing: 2

                    Repeater {
                        model: [
                            { label: "L", value: "left" },
                            { label: "C", value: "center" },
                            { label: "R", value: "right" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            readonly property bool selected: ((root.appearance.statusModulePlacement || {})[
                                moduleRow.modelData] || "right") === modelData.value
                            width: 26
                            height: 30
                            radius: root.appearance.radius
                            color: selected ? theme.accent : theme.surface

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: parent.selected ? theme.background : theme.textMuted
                                font.pixelSize: root.appearance.textSize - 3
                                font.bold: true
                            }

                            TapHandler {
                                onTapped: root.setPlacement(moduleRow.modelData, parent.modelData.value)
                            }
                        }
                    }
                }

                Rectangle {
                    width: 30
                    height: 30
                    radius: root.appearance.radius
                    color: moduleRowHover.hovered ? theme.surfaceHover : theme.surface

                    HoverHandler {
                        id: moduleRowHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Up"
                        color: theme.accent
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    TapHandler {
                        enabled: moduleRow.moduleIndex > 0
                        onTapped: root.moveModule(moduleRow.modelData, -1)
                    }
                }

                Rectangle {
                    width: 42
                    height: 30
                    radius: root.appearance.radius
                    color: downHover.hovered ? theme.surfaceHover : theme.surface

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
                        enabled: moduleRow.moduleIndex < root.modules.length - 1
                        onTapped: root.moveModule(moduleRow.modelData, 1)
                    }
                }

                Rectangle {
                    width: 36
                    height: 30
                    radius: root.appearance.radius
                    color: (root.appearance.statusModuleEnabled || {})[moduleRow.modelData] === false
                        ? theme.surface : theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: (root.appearance.statusModuleEnabled || {})[moduleRow.modelData] === false
                            ? "Off" : "On"
                        color: (root.appearance.statusModuleEnabled || {})[moduleRow.modelData] === false
                            ? theme.textMuted : theme.background
                        font.pixelSize: root.appearance.textSize - 3
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: root.setEnabled(moduleRow.modelData,
                            (root.appearance.statusModuleEnabled || {})[moduleRow.modelData] === false)
                    }
                }
            }
        }
    }
}
