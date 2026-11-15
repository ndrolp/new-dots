import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "OsdChange.js" as OsdChange

// The OSD: one change at a time (see OsdChange.js), for a moment, at the
// bottom of the screen modules/Osd.qml puts it on.
PanelWindow {
    id: root

    required property var appearance
    property real reveal: 0
    // The change shown, as OsdChange.js describes it.
    property var change: OsdChange.volume(0, false)
    readonly property var shown: OsdChange.display(change)
    readonly property bool compact: shown.compact
    readonly property color toneColor: shown.tone === "blue" ? theme.blue
        : shown.tone === "yellow" ? theme.yellow
        : shown.tone === "accent" ? theme.accent : theme.textMuted

    screen: Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null
    color: "transparent"
    // Normal: it stays inside what the monitor's bar leaves free.
    exclusionMode: ExclusionMode.Normal
    implicitWidth: compact ? osdContent.implicitWidth + 32
        : change.kind === "audioOutput" ? Math.min(460, Math.max(292, osdLabel.implicitWidth + 86)) : 292
    implicitHeight: compact ? 74 : 92
    WlrLayershell.namespace: "ndro-shell-osd"

    mask: Region {}

    // Anchored to neither left nor right, it centers in that area.
    anchors {
        bottom: true
    }

    margins {
        bottom: 36
    }

    Config.Theme {
        id: theme
    }

    // Shows `change` for a moment, replacing the one shown.
    function show(change) {
        root.change = change;
        reveal = 1;
        dismissTimer.restart();
    }

    Timer {
        id: dismissTimer

        interval: 1800
        onTriggered: root.reveal = 0
    }

    Rectangle {
        anchors.fill: parent
        radius: root.appearance.radius
        color: theme.surface
        opacity: root.reveal
        border.color: theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000"
            shadowBlur: 0.65
            shadowVerticalOffset: 6
        }

        transform: Translate {
            y: 14 * (1 - root.reveal)
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }
        }

        Behavior on transform {
            NumberAnimation {
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }
        }

        Row {
            id: osdContent

            anchors.centerIn: parent
            width: root.compact ? implicitWidth : parent.width - 32
            spacing: 12

            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: root.shown.highlighted ? theme.accent : theme.backgroundSecondary

                ShellText {
                    anchors.centerIn: parent
                    text: root.shown.icon
                    color: root.shown.highlighted ? theme.background : root.toneColor
                    font.pixelSize: 21
                    font.bold: true
                }
            }

            Column {
                width: root.compact ? implicitWidth : parent.width - 54
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                ShellText {
                    id: osdLabel

                    width: parent.width
                    text: root.shown.label
                    color: theme.text
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                Rectangle {
                    visible: root.shown.level !== null
                    width: parent.width
                    height: 6
                    radius: 3
                    color: theme.backgroundSecondary

                    Rectangle {
                        width: parent.width * (root.shown.level || 0)
                        height: parent.height
                        radius: parent.radius
                        color: root.toneColor
                    }
                }

                ShellText {
                    visible: root.shown.level !== null
                    text: Math.round((root.shown.level || 0) * 100) + "%"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }
            }
        }
    }
}
