import Quickshell

import QtQuick

import "../utils/format.js" as Format
import "../utils/settings.js" as Settings

PopupWindow {
  id: root

  required property var anchorWindow
  required property Item barContainer
  required property Item anchorTarget
  required property var colors
  required property string position
  required property int remainingSeconds
  required property int timerPresetIndex
  required property string timerState

  property bool open: false

  signal dismissed
  signal selectPresetRequested(int index)
  signal startQuickTimerRequested(int seconds)
  signal adjustTimerRequested(int delta)
  signal stopTimerRequested
  signal pauseTimerRequested
  signal startTimerRequested

  visible: open
  anchor.window: anchorWindow
  relativeX: Math.round(
    barContainer.x
    + anchorTarget.x
    + (anchorTarget.width / 2)
    - (popupCard.implicitWidth / 2)
  )
  relativeY: position === "top"
    ? Math.round(barContainer.y + barContainer.height + 8)
    : Math.round(barContainer.y - popupCard.implicitHeight - 8)
  color: "transparent"
  implicitWidth: popupCard.implicitWidth
  implicitHeight: popupCard.implicitHeight
  grabFocus: true

  onVisibleChanged: {
    if (!visible) {
      dismissed()
    }
  }

  Rectangle {
    id: popupCard

    color: colors.bg0
    border.width: 1
    border.color: colors.border0
    radius: 12
    implicitWidth: popupContent.implicitWidth + 20
    implicitHeight: popupContent.implicitHeight + 20

    Column {
      id: popupContent

      anchors.centerIn: parent
      spacing: 10

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        color: colors.fg1
        font.bold: true
        font.pointSize: 12
        text: "Create a Timer"
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Text {
          color: timerState === "running" || timerPresetIndex === 0 ? colors.fg2 : colors.fg
          font.bold: true
          font.pointSize: 18
          text: ""

          TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: timerState !== "running" && timerPresetIndex > 0
            onTapped: selectPresetRequested(timerPresetIndex - 1)
          }
        }

        Text {
          color: colors.accent2
          font.bold: true
          font.pointSize: 18
          text: Format.formatTimer(remainingSeconds, true)
        }

        Text {
          color: timerState === "running"
            || timerPresetIndex >= Settings.DEFAULT_TIMERS.length - 1
            ? colors.fg2
            : colors.fg
          font.bold: true
          font.pointSize: 18
          text: ""

          TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: timerState !== "running"
              && timerPresetIndex < Settings.DEFAULT_TIMERS.length - 1
            onTapped: selectPresetRequested(timerPresetIndex + 1)
          }
        }
      }

      Row {
        spacing: 6

        Repeater {
          model: [
            { label: "Pomodoro", seconds: 25 * 60 },
            { label: "Short Break", seconds: 5 * 60 },
            { label: "Long Break", seconds: 15 * 60 },
          ]

          delegate: Rectangle {
            required property var modelData

            color: colors.bg1
            radius: 6
            implicitWidth: quickTimerLabel.implicitWidth + 14
            implicitHeight: quickTimerLabel.implicitHeight + 10

            HoverHandler {
              id: quickHover
            }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: quickHover.hovered ? colors.bg3 : "transparent"
            }

            Text {
              id: quickTimerLabel
              anchors.centerIn: parent
              color: colors.fg
              font.bold: true
              font.pointSize: 10
              text: modelData.label
            }

            TapHandler {
              acceptedButtons: Qt.LeftButton
              onTapped: startQuickTimerRequested(modelData.seconds)
            }
          }
        }
      }

      Row {
        spacing: 6

        Repeater {
          model: [
            { label: "+1min", delta: 60 },
            { label: "-1min", delta: -60 },
            { label: "+10min", delta: 600 },
            { label: "-10min", delta: -600 },
          ]

          delegate: Rectangle {
            required property var modelData

            color: colors.bg2
            radius: 6
            implicitWidth: adjustLabel.implicitWidth + 14
            implicitHeight: adjustLabel.implicitHeight + 10

            HoverHandler {
              id: adjustHover
            }

            Rectangle {
              anchors.fill: parent
              radius: parent.radius
              color: adjustHover.hovered ? colors.bg3 : "transparent"
            }

            Text {
              id: adjustLabel
              anchors.centerIn: parent
              color: colors.fg
              font.bold: true
              font.pointSize: 10
              text: modelData.label
            }

            TapHandler {
              acceptedButtons: Qt.LeftButton
              onTapped: adjustTimerRequested(modelData.delta)
            }
          }
        }
      }

      Row {
        spacing: 6

        Rectangle {
          visible: timerState !== "stopped"
          color: colors.bg1
          radius: 6
          implicitWidth: stopLabel.implicitWidth + 28
          implicitHeight: stopLabel.implicitHeight + 12

          HoverHandler {
            id: stopHover
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: stopHover.hovered ? colors.accent6 : "transparent"
          }

          Text {
            id: stopLabel
            anchors.centerIn: parent
            color: stopHover.hovered ? colors.bg0 : colors.accent6
            font.bold: true
            font.pointSize: 12
            text: "Stop"
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: stopTimerRequested()
          }
        }

        Rectangle {
          visible: timerState === "running"
          color: colors.bg1
          radius: 6
          implicitWidth: pauseLabel.implicitWidth + 28
          implicitHeight: pauseLabel.implicitHeight + 12

          HoverHandler {
            id: pauseHover
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: pauseHover.hovered ? colors.accent1 : "transparent"
          }

          Text {
            id: pauseLabel
            anchors.centerIn: parent
            color: pauseHover.hovered ? colors.bg0 : colors.accent1
            font.bold: true
            font.pointSize: 12
            text: "Pause"
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: pauseTimerRequested()
          }
        }

        Rectangle {
          visible: timerState !== "running"
          color: colors.bg1
          radius: 6
          implicitWidth: startLabel.implicitWidth + 28
          implicitHeight: startLabel.implicitHeight + 12

          HoverHandler {
            id: startHover
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: startHover.hovered ? colors.accent2 : "transparent"
          }

          Text {
            id: startLabel
            anchors.centerIn: parent
            color: startHover.hovered ? colors.bg0 : colors.accent2
            font.bold: true
            font.pointSize: 12
            text: "Start"
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: startTimerRequested()
          }
        }
      }
    }
  }
}
