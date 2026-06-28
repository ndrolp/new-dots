import QtQuick

import "../utils/format.js" as Format
import "../utils/icons.js" as Icons

Chip {
  required property var colors
  required property var player

  visible: !!player
  fillColor: colors.bg2
  hoverColor: colors.bg3
  clickable: false

  Text {
    color: player && player.isPlaying ? colors.accent2 : colors.grey2
    font.bold: true
    font.pointSize: 10
    text: player ? Icons.getPlayerIcon(player.identity, player.trackTitle) : ""
  }

  Text {
    color: player && player.isPlaying ? colors.accent2 : colors.grey2
    font.bold: true
    font.pointSize: 10
    text: player ? Format.truncate(player.trackTitle, 30) : ""
    width: Math.min(220, implicitWidth)
    elide: Text.ElideRight
  }
}
