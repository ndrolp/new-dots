import QtQuick

Chip {
  required property var colors
  required property bool verbose
  required property var summary

  fillColor: colors.bg2
  hoverColor: colors.bg3
  clickable: false

  Text {
    color: summary.color
    font.bold: true
    font.pointSize: 10
    text: summary.icon
  }

  Text {
    visible: verbose
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: summary.label
    width: Math.min(160, implicitWidth)
    elide: Text.ElideRight
  }
}
