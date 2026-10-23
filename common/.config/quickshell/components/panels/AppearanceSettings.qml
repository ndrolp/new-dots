import QtQuick
import QtQuick.Controls
import "../../config" as Config

Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    Config.Theme {
        id: theme
    }

    Rectangle {
        width: parent.width
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
            text: "APPEARANCE PROFILE"
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
        width: parent.width
        text: "Save snapshots this page's bar settings. The background clock and desktop widgets are set per monitor in Desktop Widgets; the notification position applies to every profile."
        color: theme.textMuted
        wrapMode: Text.WordWrap
        font.pixelSize: root.appearance.textSize - 2
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: densityHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: densityHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "DENSITY PRESET"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: densitySelector

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 150
            height: 32
            textRole: "label"
            model: [
                { label: "Compact", value: "compact" },
                { label: "Balanced", value: "balanced" },
                { label: "Spacious", value: "spacious" }
            ]
            currentIndex: root.appearance.densityPreset === "compact" ? 0
                : root.appearance.densityPreset === "spacious" ? 2 : 1

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: densitySelector.displayText
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

            onActivated: root.appearance.applyDensityPreset(model[index].value)
        }
    }

    Text {
        text: "SIZE & SPACING"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 4
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
            { label: "Status island radius", from: 0, to: 32, propertyName: "statusIslandRadius" },
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
                onEditingFinished: root.appearance[modelData.propertyName] = Number(text)
            }

            SettingsSlider {
                width: parent.width
                from: modelData.from
                to: modelData.to
                stepSize: 1
                value: root.appearance[modelData.propertyName]
                onMoved: root.appearance[modelData.propertyName] = Math.round(value)
            }
        }
    }

    Text {
        text: "BAR STYLE"
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
            { label: "STATUS ISLAND", propertyName: "statusIsland" },
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
                onTapped: root.appearance[settingToggle.modelData.propertyName]
                    = !root.appearance[settingToggle.modelData.propertyName]
            }
        }
    }

    Text {
        text: "NOTIFICATIONS"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
        font.bold: true
        topPadding: 8
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: notificationLocationHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: notificationLocationHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "NOTIFICATION LOCATION"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: notificationLocationSelector

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
                { label: "Bottom left", value: "bottom-left" },
                { label: "Bottom center", value: "bottom-center" },
                { label: "Bottom right", value: "bottom-right" }
            ]
            currentIndex: {
                for (let index = 0; index < model.length; index++) {
                    if (model[index].value === root.appearance.notificationPopupLocation)
                        return index;
                }

                return 1;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: notificationLocationSelector.displayText
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

            onActivated: root.appearance.notificationPopupLocation = model[index].value
        }
    }
}
