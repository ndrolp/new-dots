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

    Repeater {
        model: [
            { label: "Bar height", from: 24, to: 56, propertyName: "barHeight" },
            { label: "Horizontal padding", from: 0, to: 48, propertyName: "horizontalPadding" },
            { label: "Pill vertical padding", from: 0, to: 8, propertyName: "pillVerticalPadding" },
            { label: "Workspace bar padding", from: 0, to: 10, propertyName: "workspacePadding" },
            { label: "Transparent bar top margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" },
            { label: "Corner radius", from: 0, to: 24, propertyName: "radius" },
            { label: "Status island radius", from: 0, to: 32, propertyName: "statusIslandRadius" },
            { label: "Component spacing", from: 0, to: 24, propertyName: "spacing" },
            { label: "Clock size", from: 48, to: 160, propertyName: "backgroundClockSize" },
            { label: "Clock opacity", from: 20, to: 100, propertyName: "backgroundClockOpacity" }
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

    Repeater {
        model: [
            { label: "TRANSPARENT BAR", propertyName: "barTransparent" },
            { label: "DOCKED ISLAND BAR", propertyName: "transparentBarSlanted" },
            { label: "STATUS ISLAND", propertyName: "statusIsland" },
            { label: "BACKGROUND CLOCK", propertyName: "backgroundClockEnabled" },
            { label: "CLOCK CALENDAR", propertyName: "backgroundClockCalendarEnabled" },
            { label: "HIDE EMPTY WORKSPACES", propertyName: "hideEmptyWorkspaces" },
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

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: clockDateFormatHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        HoverHandler {
            id: clockDateFormatHover
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
            id: clockDateFormatSelector

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
                    if (model[index].value === root.appearance.backgroundClockDateFormat)
                        return index;
                }

                return 0;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: clockDateFormatSelector.displayText
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

            onActivated: root.appearance.backgroundClockDateFormat = model[index].value
        }
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: root.appearance.radius
        color: clockPositionHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        Behavior on color {
            ColorAnimation { duration: 140 }
        }

        HoverHandler {
            id: clockPositionHover
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "CLOCK POSITION"
            color: theme.text
            font.pixelSize: root.appearance.textSize - 1
            font.bold: true
        }

        ComboBox {
            id: clockPositionSelector

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
                    if (model[index].value === root.appearance.backgroundClockPosition)
                        return index;
                }

                return 4;
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 30
                verticalAlignment: Text.AlignVCenter
                text: clockPositionSelector.displayText
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

            onActivated: root.appearance.backgroundClockPosition = model[index].value
        }
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
