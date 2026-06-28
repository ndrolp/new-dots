import QtQuick

Rectangle {
  id: root

  property color fillColor: "#363a4f"
  property color hoverColor: "#494d64"
  property bool clickable: true
  property int horizontalPadding: 8
  property int verticalPadding: 3
  property int itemSpacing: 5

  default property alias data: content.data

  signal clicked

  radius: 6
  color: hover.hovered && clickable ? hoverColor : fillColor
  implicitWidth: content.implicitWidth + horizontalPadding * 2
  implicitHeight: content.implicitHeight + verticalPadding * 2

  Row {
    id: content
    spacing: root.itemSpacing
    anchors.centerIn: parent
  }

  HoverHandler {
    id: hover
    enabled: root.clickable
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    enabled: root.clickable
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: root.clicked()
  }
}
