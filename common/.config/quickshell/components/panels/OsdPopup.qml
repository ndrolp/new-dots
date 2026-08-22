import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../config" as Config

PanelWindow {
    id: root

    required property var appearance
    property string mode: ""
    property real level: 0
    property bool capsLocked: false
    property bool capsInitialized: false
    property real reveal: 0
    property string sinkName: ""
    property string sinkType: ""
    readonly property bool compact: mode === "caps"

    readonly property var audio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
        ? Pipewire.defaultAudioSink.audio : null

    screen: Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: compact ? osdContent.implicitWidth + 32
        : mode === "sink" ? Math.min(460, Math.max(292, osdLabel.implicitWidth + 86)) : 292
    implicitHeight: compact ? 74 : 92
    WlrLayershell.namespace: "ndro-shell-osd"

    anchors {
        bottom: true
        left: true
    }

    margins {
        bottom: 36
        left: screen ? (screen.width - root.implicitWidth) / 2 : 0
    }

    Config.Theme {
        id: theme
    }

    function showVolume() {
        mode = "volume";
        level = audio && !audio.muted ? audio.volume : 0;
        reveal = 1;
        dismissTimer.restart();
    }

    function showBrightness() {
        brightnessQuery.running = true;
    }

    function showAudioSink(sink) {
        const description = String(sink.description || "");

        mode = "sink";
        sinkName = description !== "" ? description : "Audio output";
        sinkType = description.toLowerCase();
        reveal = 1;
        dismissTimer.restart();
    }

    function updateCaps(value) {
        if (capsInitialized && capsLocked !== value) {
            mode = "caps";
            capsLocked = value;
            reveal = 1;
            dismissTimer.restart();
        } else {
            capsLocked = value;
        }

        capsInitialized = true;
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Timer {
        id: dismissTimer

        interval: 1800
        onTriggered: root.reveal = 0
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (!capsQuery.running)
                capsQuery.running = true;
        }
    }

    Process {
        id: brightnessQuery

        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/(\d+(?:\.\d+)?)%/);

                if (match) {
                    root.mode = "brightness";
                    root.level = Number(match[1]) / 100;
                    root.reveal = 1;
                    dismissTimer.restart();
                }
            }
        }
    }

    Process {
        id: capsQuery

        command: ["sh", "-c", "hyprctl devices -j | jq -r '[.. | objects | select(has(\"capsLock\")) | .capsLock] | any'"]
        stdout: SplitParser {
            onRead: data => root.updateCaps(data.trim() === "true")
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.appearance.radius
        color: theme.surface
        opacity: root.reveal

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
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Behavior on transform {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
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
                color: root.mode === "caps" && root.capsLocked ? theme.accent : theme.backgroundSecondary

                Text {
                    anchors.centerIn: parent
                    text: root.mode === "volume"
                        ? (!root.audio || root.audio.muted ? "󰝟" : "󰕾")
                        : root.mode === "brightness" ? "󰃠"
                        : root.mode === "sink"
                            ? (root.sinkType.includes("headphone") || root.sinkType.includes("headset")
                                ? "󰋋"
                                : root.sinkType.includes("hdmi") || root.sinkType.includes("displayport")
                                    ? "󰍹" : "󰓃")
                            : "󰪛"
                    color: root.mode === "caps" && root.capsLocked ? theme.background
                        : root.mode === "volume" ? theme.blue
                        : root.mode === "brightness" ? theme.yellow
                        : root.mode === "sink" ? theme.accent : theme.textMuted
                    font.pixelSize: 21
                    font.bold: true
                }
            }

            Column {
                width: root.compact ? implicitWidth : parent.width - 54
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    id: osdLabel

                    width: parent.width
                    text: root.mode === "volume" ? "Volume"
                        : root.mode === "brightness" ? "Brightness"
                        : root.mode === "sink" ? sinkName
                        : root.capsLocked ? "Caps Lock on" : "Caps Lock off"
                    color: theme.text
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                Rectangle {
                    visible: root.mode === "volume" || root.mode === "brightness"
                    width: parent.width
                    height: 6
                    radius: 3
                    color: theme.backgroundSecondary

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.level))
                        height: parent.height
                        radius: parent.radius
                        color: root.mode === "volume" ? theme.blue : theme.yellow
                    }
                }

                Text {
                    visible: root.mode === "volume" || root.mode === "brightness"
                    text: Math.round(root.level * 100) + "%"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }
            }
        }
    }
}
