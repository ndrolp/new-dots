import QtQuick

import "../utils/icons.js" as Icons

Chip {
  required property var colors
  required property var activeSink
  required property bool verbose
  required property int volumePercent

  fillColor: colors.bg2
  hoverColor: colors.bg3
  clickable: false

  Text {
    color: colors.accent3
    font.bold: true
    font.pointSize: 10
    text: Icons.getVolumeIcon(activeSink ? activeSink.volume : 0, activeSink ? activeSink.muted : false)
  }

  Text {
    visible: !verbose && !!activeSink && activeSink.volume > 0
    color: colors.accent3
    font.bold: true
    font.pointSize: 10
    text: Icons.getVolumeBar(activeSink ? activeSink.volume : 0)
  }

  Text {
    visible: verbose && !!activeSink
    color: activeSink && activeSink.muted ? colors.accent6 : colors.accent3
    font.bold: true
    font.pointSize: 10
    text: volumePercent + "%"
  }
}
