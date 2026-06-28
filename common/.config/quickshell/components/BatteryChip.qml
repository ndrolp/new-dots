import QtQuick

import "../utils/icons.js" as Icons

Chip {
  required property var colors
  required property bool verbose
  required property bool batteryVisible
  required property var batteryDevice
  required property string batteryStateName
  required property int batteryPercent

  visible: batteryVisible
  fillColor: colors.bg2
  hoverColor: colors.bg3
  clickable: false

  Text {
    color: colors.accent4
    font.bold: true
    font.pointSize: 10
    text: Icons.getBatteryIcon(batteryStateName, batteryDevice ? batteryDevice.percentage : 0)
  }

  Text {
    visible: verbose
    color: colors.accent4
    font.bold: true
    font.pointSize: 10
    text: batteryPercent + "%"
  }
}
