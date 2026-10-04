import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../config" as Config

Variants {
    id: root

    required property var appearance
    property bool open: false

    signal closeRequested()
    signal audioSinksRequested()
    signal controlCenterRequested()
    signal settingsRequested()
    signal themeSelectorRequested()
    signal wallpaperSelectorRequested()
    signal powerMenuRequested()
    signal profileRequested(string profile)

    model: Quickshell.screens

    delegate: PanelWindow {
        id: palette

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        readonly property var audio: Pipewire.defaultAudioSink?.audio || null
        readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
        property string query: ""
        property int selectedIndex: 0
        property real brightness: 0
        property bool brightnessAvailable: false
        property string powerProfile: ""
        property bool powerProfileAvailable: false
        readonly property var filteredActions: actions().filter(action => {
            const needle = query.trim().toLowerCase();
            return needle === "" || (action.title + " " + action.subtitle + " "
                + action.category).toLowerCase().includes(needle);
        })

        screen: modelData
        visible: root.open && focusedMonitor
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-quick-settings"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Config.Theme {
            id: theme
        }

        Process {
            id: actionProcess
        }

        Process {
            id: brightnessQuery

            command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4"]
            stdout: SplitParser {
                onRead: data => {
                    const match = data.match(/(\d+(?:\.\d+)?)%/);
                    if (match) {
                        palette.brightness = Number(match[1]) / 100;
                        palette.brightnessAvailable = true;
                    }
                }
            }
        }

        Process {
            id: powerProfileQuery

            command: ["powerprofilesctl", "get"]
            stdout: SplitParser {
                onRead: data => {
                    const profile = data.trim();
                    if (profile !== "") {
                        palette.powerProfile = profile;
                        palette.powerProfileAvailable = true;
                    }
                }
            }
        }

        function actions() {
            const volume = audio ? Math.round(audio.volume * 100) + "%" : "Unavailable";
            const output = Pipewire.defaultAudioSink
                ? String(Pipewire.defaultAudioSink.description || "Default output") : "Unavailable";
            const bluetooth = bluetoothAdapter ? (bluetoothAdapter.enabled ? "On" : "Off")
                : "Unavailable";
            const brightnessText = brightnessAvailable ? Math.round(brightness * 100) + "%"
                : "Unavailable";
            const profile = powerProfileAvailable ? powerProfile : "Unavailable";

            return [
                { id: "volume-down", category: "AUDIO", title: "Volume down", subtitle: volume,
                    glyph: "󰖀", color: theme.blue, enabled: !!audio },
                { id: "volume-up", category: "AUDIO", title: "Volume up", subtitle: volume,
                    glyph: "󰕾", color: theme.blue, enabled: !!audio },
                { id: "mute", category: "AUDIO", title: audio?.muted ? "Unmute audio" : "Mute audio",
                    subtitle: volume, glyph: audio?.muted ? "󰖁" : "󰖂", color: theme.red,
                    enabled: !!audio },
                { id: "output", category: "AUDIO", title: "Select audio output", subtitle: output,
                    glyph: "󰓃", color: theme.accent, enabled: !!Pipewire.defaultAudioSink },
                { id: "brightness-down", category: "DISPLAY", title: "Brightness down",
                    subtitle: brightnessText, glyph: "󰃞", color: theme.yellow,
                    enabled: brightnessAvailable },
                { id: "brightness-up", category: "DISPLAY", title: "Brightness up",
                    subtitle: brightnessText, glyph: "󰃠", color: theme.yellow,
                    enabled: brightnessAvailable },
                { id: "wifi", category: "CONNECTIVITY",
                    title: Networking.wifiEnabled ? "Turn Wi-Fi off" : "Turn Wi-Fi on",
                    subtitle: Networking.wifiEnabled ? "Enabled" : "Disabled", glyph: "󰤨",
                    color: theme.purple, enabled: true },
                { id: "bluetooth", category: "CONNECTIVITY",
                    title: bluetoothAdapter?.enabled ? "Turn Bluetooth off" : "Turn Bluetooth on",
                    subtitle: bluetooth, glyph: "󰂯", color: theme.blue,
                    enabled: !!bluetoothAdapter },
                { id: "dnd", category: "SYSTEM",
                    title: root.appearance.doNotDisturb ? "Disable Do Not Disturb"
                        : "Enable Do Not Disturb",
                    subtitle: root.appearance.doNotDisturb ? "Notifications paused"
                        : "Notifications allowed",
                    glyph: root.appearance.doNotDisturb ? "󰂛" : "󰂚", color: theme.orange,
                    enabled: true },
                { id: "power-profile", category: "SYSTEM", title: "Cycle power profile",
                    subtitle: profile, glyph: "󱐋", color: theme.green,
                    enabled: powerProfileAvailable },
                { id: "profile-minimal", category: "APPEARANCE", title: "Bar profile: Minimal",
                    subtitle: "Compact essentials", glyph: "󰝟", color: theme.text, enabled: true },
                { id: "profile-work", category: "APPEARANCE", title: "Bar profile: Work",
                    subtitle: "Current working layout", glyph: "󰖟", color: theme.text, enabled: true },
                { id: "profile-media", category: "APPEARANCE", title: "Bar profile: Media",
                    subtitle: "Media-focused layout", glyph: "󰎆", color: theme.text, enabled: true },
                { id: "profile-presentation", category: "APPEARANCE",
                    title: "Bar profile: Presentation", subtitle: "Minimal distraction",
                    glyph: "󰐹", color: theme.text, enabled: true },
                { id: "wallpapers", category: "OPEN", title: "Choose wallpaper",
                    subtitle: "Wallpaper selector", glyph: "󰸉", color: theme.purple, enabled: true },
                { id: "themes", category: "OPEN", title: "Choose theme",
                    subtitle: "Theme selector", glyph: "󰔎", color: theme.pink, enabled: true },
                { id: "settings", category: "OPEN", title: "Open shell settings",
                    subtitle: "Appearance, displays, widgets, and bar", glyph: "󰒓",
                    color: theme.blue, enabled: true },
                { id: "control-center", category: "OPEN", title: "Open Control Center",
                    subtitle: "Expanded system controls", glyph: "󰕮", color: theme.accent,
                    enabled: true },
                { id: "lock", category: "POWER", title: "Lock session",
                    subtitle: "Lock immediately", glyph: "󰌾", color: theme.blue, enabled: true },
                { id: "power-menu", category: "POWER", title: "Open power menu",
                    subtitle: "Suspend, logout, reboot, or shutdown", glyph: "󰐥",
                    color: theme.red, enabled: true }
            ];
        }

        function close() {
            root.closeRequested();
        }

        function selectRelative(offset) {
            if (filteredActions.length === 0)
                return;

            selectedIndex = (selectedIndex + offset + filteredActions.length) % filteredActions.length;
            actionList.positionViewAtIndex(selectedIndex, ListView.Contain);
        }

        function run(command) {
            actionProcess.command = command;
            actionProcess.running = true;
        }

        function activate(action) {
            if (!action || !action.enabled)
                return;

            if (action.id === "volume-down")
                run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
            else if (action.id === "volume-up")
                run(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "5%+"]);
            else if (action.id === "mute")
                run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
            else if (action.id === "output")
                root.audioSinksRequested();
            else if (action.id === "brightness-down")
                run(["brightnessctl", "set", "5%-"]);
            else if (action.id === "brightness-up")
                run(["brightnessctl", "set", "5%+"]);
            else if (action.id === "wifi")
                Networking.wifiEnabled = !Networking.wifiEnabled;
            else if (action.id === "bluetooth")
                bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
            else if (action.id === "dnd")
                root.appearance.doNotDisturb = !root.appearance.doNotDisturb;
            else if (action.id === "power-profile")
                run(["powerprofilesctl", "set", powerProfile === "power-saver"
                    ? "balanced" : powerProfile === "balanced" ? "performance" : "power-saver"]);
            else if (action.id.startsWith("profile-"))
                root.profileRequested(action.id.slice("profile-".length));
            else if (action.id === "wallpapers")
                root.wallpaperSelectorRequested();
            else if (action.id === "themes")
                root.themeSelectorRequested();
            else if (action.id === "settings")
                root.settingsRequested();
            else if (action.id === "control-center")
                root.controlCenterRequested();
            else if (action.id === "lock")
                run(["loginctl", "lock-session"]);
            else if (action.id === "power-menu")
                root.powerMenuRequested();
            else
                return;

            close();
        }

        function activateCurrent() {
            activate(filteredActions[selectedIndex]);
        }

        function activateById(id) {
            const action = actions().find(candidate => candidate.id === id);
            if (action)
                activate(action);
        }

        onVisibleChanged: {
            if (!visible)
                return;

            query = "";
            selectedIndex = 0;
            brightnessAvailable = false;
            powerProfileAvailable = false;
            brightnessQuery.running = true;
            powerProfileQuery.running = true;
            focusTimer.restart();
        }

        Timer {
            id: focusTimer

            interval: 1
            onTriggered: searchInput.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            TapHandler {
                onTapped: palette.close()
            }
        }

        Rectangle {
            id: card

            anchors.centerIn: parent
            width: Math.min(parent.width - 64, 720)
            height: Math.min(parent.height - 72, 620)
            radius: root.appearance.radius
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.9)
            border.color: theme.border
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 9

                Row {
                    width: parent.width

                    Text {
                        text: "QUICK SETTINGS"
                        color: theme.text
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize + 1
                        font.bold: true
                    }

                    Item { width: parent.width - parent.children[0].implicitWidth - 52; height: 1 }

                    Text {
                        text: "Esc close"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                TextField {
                    id: searchInput

                    width: parent.width
                    height: 42
                    placeholderText: "Filter settings and actions"
                    placeholderTextColor: theme.textMuted
                    color: theme.text
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize
                    leftPadding: 38
                    text: palette.query
                    selectByMouse: true

                    background: Rectangle {
                        radius: root.appearance.radius
                        color: theme.backgroundSecondary
                        border.color: searchInput.activeFocus ? theme.accent : theme.border
                        border.width: 1
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        color: theme.textMuted
                        font.pixelSize: 17
                    }

                    onTextEdited: {
                        palette.query = text;
                        palette.selectedIndex = 0;
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            palette.selectRelative(1);
                        } else if (event.key === Qt.Key_Up) {
                            palette.selectRelative(-1);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            palette.activateCurrent();
                        } else if (event.key === Qt.Key_Escape) {
                            palette.close();
                        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_M) {
                            palette.activateById("mute");
                        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_W) {
                            palette.activateById("wifi");
                        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_B) {
                            palette.activateById("bluetooth");
                        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_N) {
                            palette.activateById("dnd");
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }

                Text {
                    width: parent.width
                    text: "↑↓ select  •  Enter activate  •  Ctrl+M mute  •  Ctrl+W Wi-Fi"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: root.appearance.textSize - 4
                    elide: Text.ElideRight
                }

                ListView {
                    id: actionList

                    width: parent.width
                    height: parent.height - 42 - 25 - 17 - parent.spacing * 3
                    clip: true
                    spacing: 3
                    model: palette.filteredActions
                    currentIndex: palette.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: actionDelegate

                        required property var modelData
                        required property int index
                        readonly property var action: modelData
                        readonly property bool categoryStart: index === 0
                            || action.category !== palette.filteredActions[index - 1].category
                        readonly property bool selected: index === palette.selectedIndex

                        width: actionList.width
                        height: (categoryStart ? 21 : 0) + 48

                        Text {
                            visible: actionDelegate.categoryStart
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: actionDelegate.action.category
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: root.appearance.textSize - 4
                            font.bold: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: actionDelegate.categoryStart ? 21 : 0
                            height: 48
                            radius: root.appearance.radius
                            color: actionDelegate.selected ? Qt.rgba(theme.accent.r, theme.accent.g,
                                theme.accent.b, 0.18) : actionHover.hovered ? theme.surfaceHover
                                    : theme.backgroundSecondary
                            border.color: actionDelegate.selected ? theme.accent : "transparent"
                            border.width: actionDelegate.selected ? 1 : 0
                            opacity: actionDelegate.action.enabled ? 1 : 0.46

                            HoverHandler { id: actionHover }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                text: actionDelegate.action.glyph
                                color: actionDelegate.action.color
                                font.pixelSize: 18
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 45
                                anchors.right: parent.right
                                anchors.rightMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: actionDelegate.action.title
                                    color: theme.text
                                    font.family: theme.fontFamily
                                    font.pixelSize: root.appearance.textSize - 1
                                    font.bold: actionDelegate.selected
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: actionDelegate.action.subtitle
                                    color: theme.textMuted
                                    font.family: theme.fontFamily
                                    font.pixelSize: root.appearance.textSize - 4
                                    elide: Text.ElideRight
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    palette.selectedIndex = index;
                                    palette.activate(actionDelegate.action);
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: actionList.count === 0
                        text: "No matching quick settings"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: root.appearance.textSize
                    }
                }
            }
        }
    }
}
