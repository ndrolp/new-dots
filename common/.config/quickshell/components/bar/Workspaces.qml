import QtQuick
import "../BarPosition.js" as BarPosition
import "../../config" as Config
import "../../config/BarProfileModel.js" as BarProfileModel
import "BarLayout.js" as BarLayout

Rectangle {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var monitorScreen
    required property var monitors
    required property var workspaceService

    readonly property bool ownPill: appearance.barTransparent && !grouped
    readonly property var options: BarProfileModel.elementOptions(appearance.barElements, "workspaces")

    readonly property bool sideBar: BarPosition.sideBar(appearance.barPosition)
    // How thick the buttons are across the bar: on an opaque bar they fill it
    // but for the vertical padding on either side.
    readonly property real buttonThickness: appearance.barTransparent
        ? appearance.workspaceButtonSize - 2
        : Math.max(1, appearance.barHeight - options.verticalPadding * 2)
    // The element wraps its line of buttons, which runs along the bar, and its
    // own pill adds the vertical padding on either side.
    readonly property var size: BarLayout.size(appearance,
        (sideBar ? workspaceStack.implicitHeight : workspaceStack.implicitWidth) + (ownPill ? 16 : 0),
        buttonThickness + (ownPill ? options.verticalPadding * 2 : 0))

    implicitWidth: size.width
    implicitHeight: size.height
    width: implicitWidth
    height: implicitHeight
    radius: appearance.radius
    color: appearance.barTransparent && !appearance.pillsTransparent
        && !appearance.transparentBarSlanted && !grouped ? theme.surface : "transparent"
    border.width: appearance.elementBorder && !grouped ? 1 : 0
    border.color: appearance.elementBorder ? theme.border : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: root.appearance.motion.short
        }
    }

    AlongBarBehavior on width { appearance: root.appearance }
    AlongBarBehavior on height { appearance: root.appearance }

    ElementStack {
        id: workspaceStack

        anchors.centerIn: parent
        appearance: root.appearance
        spacing: root.appearance.spacing

        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }
        }

        Repeater {
            model: root.workspaceService.workspacesForScreen(
                root.monitorScreen,
                root.monitors.workspacesFor(root.workspaceService.monitorDescriptionForScreen(root.monitorScreen))
            ).filter(workspaceId => !root.options.hideEmpty
                || root.workspaceService.isActive(workspaceId)
                || root.workspaceService.isOccupied(workspaceId)
                || root.workspaceService.isUrgent(workspaceId))

            delegate: Rectangle {
                id: workspaceButton

                required property var modelData
                readonly property int workspaceId: modelData
                readonly property bool active: root.workspaceService.isActive(workspaceId)
                readonly property bool occupied: root.workspaceService.isOccupied(workspaceId)
                readonly property int toplevelCount: root.workspaceService.toplevelCount(workspaceId)
                readonly property bool urgent: !active
                    && root.workspaceService.isUrgent(workspaceId)
                readonly property string workspaceGlyph: root.options.glyphsEnabled
                    && root.options.glyphs.length >= workspaceId
                    ? String(root.options.glyphs[workspaceId - 1]).trim() : ""

                readonly property var size: BarLayout.size(appearance, active
                    ? appearance.workspaceButtonSize + (appearance.activeWorkspaceHorizontalPadding * 2)
                    : appearance.workspaceButtonSize, root.buttonThickness)

                width: size.width
                height: size.height
                radius: root.options.radius
                color: active ? theme.accent : urgent
                    ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.22)
                    : occupied && !appearance.pillsTransparent && !appearance.transparentBarSlanted
                        && !root.grouped
                        ? theme.surface : "transparent"
                border.color: urgent ? theme.red : "transparent"
                border.width: urgent ? 1 : 0

                AlongBarBehavior on width { appearance: root.appearance }
                AlongBarBehavior on height { appearance: root.appearance }
                AlongBarBehavior on x { appearance: root.appearance }
                AlongBarBehavior on y { appearance: root.appearance }

                Behavior on color {
                    ColorAnimation {
                        duration: root.appearance.motion.short
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: workspaceButton.workspaceGlyph !== ""
                        ? workspaceButton.workspaceGlyph : workspaceButton.workspaceId
                    color: workspaceButton.active ? theme.background : workspaceButton.urgent
                        ? theme.red : workspaceButton.occupied ? theme.text : theme.textDisabled
                    font.family: theme.fontFamily
                    font.pixelSize: appearance.textSize
                    font.bold: true

                    Behavior on color {
                        ColorAnimation {
                            duration: root.appearance.motion.brief
                        }
                    }

                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: -3
                    anchors.top: parent.top
                    anchors.topMargin: -3
                    width: 12
                    height: 12
                    radius: width / 2
                    color: workspaceButton.urgent ? theme.red : theme.backgroundSecondary
                    border.color: workspaceButton.urgent ? theme.red : theme.border
                    border.width: 1
                    visible: root.options.appCountVisible
                        && workspaceButton.occupied && !workspaceButton.active
                    z: 2

                    Text {
                        anchors.centerIn: parent
                        text: workspaceButton.toplevelCount > 9 ? "9+" : workspaceButton.toplevelCount
                        color: workspaceButton.urgent ? theme.background : theme.textMuted
                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                HoverHandler {
                    id: hover
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.options.radius
                    color: theme.surfaceHover
                    opacity: hover.hovered && !workspaceButton.active ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.appearance.motion.short
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: workspaceButton.workspaceGlyph !== ""
                            ? workspaceButton.workspaceGlyph : workspaceButton.workspaceId
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: appearance.textSize
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.workspaceService.switchTo(workspaceButton.workspaceId)
                }
            }
        }
    }

    Config.Theme {
        id: theme
    }
}
