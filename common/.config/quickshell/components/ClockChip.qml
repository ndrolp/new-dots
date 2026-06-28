import QtQuick

Chip {
  required property var colors
  required property string label

  fillColor: colors.bg2
  hoverColor: colors.bg3

  Text {
    color: colors.accent1
    font.bold: true
    font.pointSize: 10
    text: "󰥔"
  }

  Text {
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: label
  }
}
