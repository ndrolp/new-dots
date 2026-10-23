import QtQuick
import "../../config" as Config

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Text {
        text: "SIZE & SPACING"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 4
    }

    // Density presets fill in the sizes below in one go; they are a pending
    // change like any other and the preset itself is not stored.
    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: theme.backgroundSecondary

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "DENSITY PRESET"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: [
                    { label: "Compact", value: "compact" },
                    { label: "Balanced", value: "balanced" },
                    { label: "Spacious", value: "spacious" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool matching: root.appearance.matchingDensityPreset === modelData.value

                    width: 84
                    height: 32
                    radius: root.appearance.radius
                    color: matching ? theme.accent : presetHover.hovered ? theme.surfaceHover : theme.surface

                    HoverHandler {
                        id: presetHover
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: parent.matching ? theme.background : theme.accent
                        font.pixelSize: root.appearance.textSize - 2
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: root.appearance.applyDensityPreset(parent.modelData.value)
                    }
                }
            }
        }
    }

    Repeater {
        model: [
            { label: "Bar height", from: 24, to: 56, propertyName: "barHeight" },
            { label: "Bar opacity", from: 20, to: 100, propertyName: "barOpacity" },
            { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
            { label: "Pill vertical padding", from: 0, to: 8, propertyName: "pillVerticalPadding" },
            { label: "Workspace bar padding", from: 0, to: 10, propertyName: "workspacePadding" },
            { label: "Bar vertical padding", from: 0, to: 16, propertyName: "structuralVerticalPadding" },
            { label: "Transparent bar top margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" },
            { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
            { label: "Group radius", from: 0, to: 32, propertyName: "groupRadius" },
            { label: "Component spacing", from: 0, to: 24, propertyName: "spacing" }
        ]

        delegate: Column {
            required property var modelData

            width: parent.width
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
                text: String(root.appearance[modelData.propertyName])
                validator: IntValidator {
                    bottom: modelData.from
                    top: modelData.to
                }
                onEditingFinished: root.appearance.setBarSetting(modelData.propertyName, Number(text))
            }

            SettingsSlider {
                width: parent.width
                from: modelData.from
                to: modelData.to
                stepSize: 1
                value: root.appearance[modelData.propertyName]
                onMoved: root.appearance.setBarSetting(modelData.propertyName, Math.round(value))
            }
        }
    }

    Text {
        text: "STYLE"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 8
    }

    Repeater {
        model: [
            { label: "TRANSPARENT BAR", propertyName: "barTransparent" },
            { label: "TRANSPARENT BAR BORDER", propertyName: "barTransparentBorder" },
            { label: "DOCKED ISLAND BAR", propertyName: "transparentBarSlanted" },
            { label: "TRANSPARENT PILLS", propertyName: "pillsTransparent" }
        ]

        delegate: Rectangle {
            id: settingToggle

            required property var modelData

            width: parent.width
            height: 44
            radius: root.appearance.radius
            color: toggleHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

            Behavior on color {
                ColorAnimation { duration: 140 }
            }

            HoverHandler {
                id: toggleHover
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: settingToggle.modelData.label
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
                color: root.appearance[settingToggle.modelData.propertyName] ? theme.accent : theme.surface

                Rectangle {
                    x: root.appearance[settingToggle.modelData.propertyName] ? parent.width - width - 3 : 3
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
                onTapped: root.appearance.setBarSetting(settingToggle.modelData.propertyName,
                    !root.appearance[settingToggle.modelData.propertyName])
            }
        }
    }
}
