import QtQuick

import "../utils/format.js" as Format

Chip {
  required property var colors
  required property string timerState
  required property int remainingSeconds

  fillColor: colors.bg2
  hoverColor: colors.bg3

  Text {
    color: colors.accent1
    font.bold: true
    font.pointSize: 10
    text: ""
  }

  Text {
    visible: timerState !== "stopped"
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: Format.formatTimer(remainingSeconds, false)
  }
}
