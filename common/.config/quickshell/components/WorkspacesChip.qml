import QtQuick
import Quickshell.Hyprland._Ipc


import "../utils/settings.js" as Settings


Chip {
  required property var colors
  required property var workspaceConfig
  required property int workspaceCount
  required property var shouldShowWorkspace
  required property var workspaceBackground
  required property var workspaceTextColor

  fillColor: colors.bg2
  hoverColor: colors.bg2
  clickable: false
  horizontalPadding: 6

  Row {
    spacing: 2

    Repeater {
      model: workspaceCount

      delegate: Rectangle {
        required property int index

        readonly property int workspaceId: workspaceConfig.from + index

        visible: shouldShowWorkspace(workspaceId)
        color: workspaceBackground(workspaceId)
        radius: height / 2
        implicitWidth: workspaceLabel.implicitWidth + 16
        implicitHeight: workspaceLabel.implicitHeight + 0

        HoverHandler {
          id: workspaceHover
        }

        TapHandler {
          acceptedButtons: Qt.LeftButton
          gesturePolicy: TapHandler.ReleaseWithinBounds
          onTapped: Hyprland.dispatch("workspace " + workspaceId)
        }

        Rectangle {
          anchors.fill: parent
          radius: parent.radius
          color: workspaceHover.hovered && parent.color === "transparent"
            ? Qt.rgba(1, 1, 1, 0.05)
            : "transparent"
        }

        Text {
          id: workspaceLabel
          anchors.centerIn: parent
          color: workspaceTextColor(workspaceId)
          font.bold: true
          font.pointSize: 10
          text: Settings.workspaceLabel(workspaceId)
        }
      }
    }
  }
}
