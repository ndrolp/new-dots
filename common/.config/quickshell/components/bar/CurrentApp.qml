import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config" as Config

Row {
    id: root

    required property var appearance
    required property var monitorScreen

    readonly property var rawActiveToplevel: Hyprland.activeToplevel
    readonly property var monitor: Hyprland.monitorFor(monitorScreen)
    readonly property var activeToplevel: rawActiveToplevel
        && rawActiveToplevel.workspace
        && Hyprland.focusedWorkspace
        && rawActiveToplevel.workspace.id === Hyprland.focusedWorkspace.id
        ? rawActiveToplevel : null
    readonly property string appId: activeToplevel && activeToplevel.wayland
        ? activeToplevel.wayland.appId : ""
    readonly property bool terminal: isTerminal(appId)
    readonly property string windowTitle: activeToplevel ? activeToplevel.title.trim() : ""
    readonly property string label: appId !== ""
        ? appId + (windowTitle !== "" && windowTitle.toLowerCase() !== appId.toLowerCase()
            ? ": " + windowTitle : "")
        : windowTitle !== "" ? windowTitle : "Desktop"
    readonly property string iconName: terminal ? terminalIconName(windowTitle) : appId
    readonly property string iconSource: iconName !== ""
        ? Quickshell.iconPath(iconName, true) : ""
    readonly property string terminalGlyph: terminal ? terminalIconGlyph(windowTitle) : ""
    readonly property real activeTitleMaximumWidth: monitorScreen
        ? Math.max(120, Math.min(320, monitorScreen.width * 0.14)) : 320

    spacing: appearance.spacing
    visible: label !== "" && monitor !== null && Hyprland.focusedWorkspace
        && Hyprland.focusedWorkspace.monitor !== null
        && Hyprland.focusedWorkspace.monitor.name === monitor.name
    width: visible ? implicitWidth : 0

    Config.Theme {
        id: theme
    }

    function isTerminal(id) {
        const terminalIds = [
            "kitty", "foot", "alacritty", "wezterm", "org.wezfurlong.wezterm",
            "com.mitchellh.ghostty", "gnome-terminal-server", "konsole", "xterm"
        ];

        return terminalIds.indexOf(id.toLowerCase()) !== -1;
    }

    function terminalIconName(title) {
        const command = title.toLowerCase();

        if (command.includes("github copilot") || command.includes("lazygit"))
            return "github-desktop";
        if (command.includes("neovim") || command.includes("nvim") || command.includes("vim"))
            return "nvim";
        if (command.includes("btop") || command.includes("bashtop"))
            return "btop";
        if (command.includes("htop"))
            return "utilities-system-monitor";
        if (command.includes("yazi") || command.includes("ranger") || command.includes("lf"))
            return "system-file-manager";
        if (command.includes("docker"))
            return "docker";
        if (command.includes("ssh"))
            return "network-server";
        return "utilities-terminal";
    }

    function terminalIconGlyph(title) {
        const command = title.toLowerCase();

        if (command.includes("github copilot") || command.includes("lazygit"))
            return "󰊤";
        if (command.includes("neovim") || command.includes("nvim") || command.includes("vim"))
            return "";
        if (command.includes("btop") || command.includes("bashtop") || command.includes("htop"))
            return "󰊚";
        if (command.includes("yazi") || command.includes("ranger") || command.includes("lf"))
            return "󰉋";
        if (command.includes("docker"))
            return "󰡨";
        if (command.includes("ssh"))
            return "󰒋";
        return "󰆍";
    }

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        width: appContent.implicitWidth + 16
        height: appearance.workspaceButtonSize + (appearance.pillVerticalPadding * 2)
        radius: appearance.radius
        color: appHover.hovered ? theme.surfaceHover
            : root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.appearance.statusIsland ? "transparent" : theme.surface

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        HoverHandler {
            id: appHover
        }

        Row {
            id: appContent

            anchors.centerIn: parent
            spacing: icon.displayedIconSource === ""
                ? root.appearance.spacing + 2 : root.appearance.spacing

            Item {
                id: icon

                property string displayedIconSource: root.iconSource
                property string displayedTerminalGlyph: root.terminalGlyph

                visible: root.activeToplevel !== null
                width: visible ? root.appearance.workspaceButtonSize - 8 : 0
                height: Math.max(appName.implicitHeight, width)

                transform: Translate {
                    id: iconTranslation
                }

                Image {
                    anchors.centerIn: parent
                    width: icon.width
                    height: icon.width
                    source: icon.displayedIconSource
                    fillMode: Image.PreserveAspectFit
                    visible: icon.displayedIconSource !== "" && icon.displayedTerminalGlyph === ""
                }

                Text {
                    anchors.fill: parent
                    visible: icon.displayedTerminalGlyph !== ""
                        || icon.displayedIconSource === ""
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: icon.displayedTerminalGlyph !== ""
                        ? icon.displayedTerminalGlyph : "󰣆"
                    color: icon.displayedTerminalGlyph !== "" ? theme.blue : theme.text
                    font.pixelSize: appearance.textSize
                    font.bold: true
                }
            }

            Text {
                id: appName

                property string displayedLabel: root.label

                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(root.activeTitleMaximumWidth, implicitWidth)
                text: displayedLabel
                color: theme.text
                elide: Text.ElideRight
                font.pixelSize: appearance.textSize
                font.bold: true

                transform: Translate {
                    id: labelTranslation
                }
            }
        }
    }

    SequentialAnimation {
        id: labelTransition

        ParallelAnimation {
            NumberAnimation {
                target: labelTranslation
                property: "x"
                to: -12
                duration: 90
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: -12
                duration: 90
            }
        }

        ScriptAction {
            script: {
                appName.displayedLabel = root.label;
                icon.displayedIconSource = root.iconSource;
                icon.displayedTerminalGlyph = root.terminalGlyph;
                labelTranslation.x = 12;
                iconTranslation.x = 12;
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: labelTranslation
                property: "x"
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    onLabelChanged: labelTransition.restart()
}
