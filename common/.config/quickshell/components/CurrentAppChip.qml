import QtQuick

import "../utils/format.js" as Format
import "../utils/icons.js" as Icons

Chip {
  required property var colors
  required property string appClass
  required property string title
  property bool active: false

  visible: active
  fillColor: colors.bg2
  hoverColor: colors.bg3
  clickable: false
  horizontalPadding: 10

  Text {
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: Icons.getActiveClientIcon(appClass, title)
  }

  Text {
    color: colors.fg
    font.bold: true
    font.pointSize: 10
    text: Format.truncate(title, 42)
    width: Math.min(320, implicitWidth)
    elide: Text.ElideRight
  }
}
