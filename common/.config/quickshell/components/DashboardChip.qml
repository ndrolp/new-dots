import QtQuick

Chip {
  required property var colors

  fillColor: colors.bg2
  hoverColor: colors.bg2
  clickable: false
  opacity: 0.95

  Text {
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: ""
  }
}
