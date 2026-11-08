import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config" as Config
import "../IconSource.js" as IconSource
import "../FocusedWindow.js" as FocusedWindow
import "BarLayout.js" as BarLayout

// On a side bar the text runs sideways with its ellipsis and the icon stays
// upright, on top of it.
Row {
    id: root

    required property var appearance
    // Inside a group the shared background replaces this element's pill.
    property bool grouped: false
    required property var monitorScreen
    property bool enabled: true

    readonly property var monitor: Hyprland.monitorFor(monitorScreen)
    readonly property var activeToplevel: FocusedWindow.focusedWindow(Hyprland.activeToplevel,
        Hyprland.focusedWorkspace)
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
        ? IconSource.forName(iconName) : ""
    readonly property string terminalGlyph: terminal ? terminalIconGlyph(windowTitle) : ""
    readonly property real activeTitleMaximumWidth: monitorScreen
        ? Math.max(120, Math.min(320, BarLayout.screenLength(appearance, monitorScreen) * 0.14)) : 320
    readonly property real thickness: BarLayout.elementThickness(appearance)
    readonly property real length: appContent.implicitWidth + 16
    readonly property var size: BarLayout.size(appearance, visible ? length : 0, thickness)

    spacing: appearance.spacing
    visible: enabled && label !== "" && FocusedWindow.onFocusedMonitor(monitor, Hyprland.focusedWorkspace)
    width: size.width
    height: size.height

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

    AlongBarBehavior on width { appearance: root.appearance }
    AlongBarBehavior on height { appearance: root.appearance }

    Rectangle {
        readonly property var size: BarLayout.size(appearance, root.length, root.thickness)

        width: size.width
        height: size.height
        radius: appearance.radius
        color: appHover.hovered ? theme.surfaceHover
            : root.appearance.pillsTransparent || root.appearance.transparentBarSlanted
                || root.grouped ? "transparent" : theme.surface

        border.width: appearance.elementBorder && !root.grouped ? 1 : 0
        border.color: appearance.elementBorder ? theme.border : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: root.appearance.motion.short
            }
        }

        HoverHandler {
            id: appHover
        }

        Row {
            id: appContent

            anchors.centerIn: parent
            // As thick as the background, so its center is the background's.
            height: root.thickness
            rotation: BarLayout.turn(root.appearance)
            spacing: icon.displayedIconSource === ""
                ? root.appearance.spacing + 2 : root.appearance.spacing

            Item {
                id: icon

                property string displayedIconSource: root.iconSource
                property string displayedTerminalGlyph: root.terminalGlyph

                anchors.verticalCenter: parent.verticalCenter
                rotation: -parent.rotation
                visible: root.activeToplevel !== null
                width: visible ? root.appearance.workspaceButtonSize - 8 : 0
                height: width

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

                ShellText {
                    id: glyph

                    // Centers the glyph's drawn shape, not its line box.
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.alignWhenCentered: false
                    anchors.verticalCenterOffset: height / 2 - (baselineOffset
                        + glyphMetrics.tightBoundingRect.y
                        + glyphMetrics.tightBoundingRect.height / 2)
                    visible: icon.displayedTerminalGlyph !== ""
                        || icon.displayedIconSource === ""
                    horizontalAlignment: Text.AlignHCenter
                    text: icon.displayedTerminalGlyph !== ""
                        ? icon.displayedTerminalGlyph : "󰣆"
                    color: icon.displayedTerminalGlyph !== "" ? theme.blue : theme.text
                    font.pixelSize: appearance.textSize
                    font.bold: true

                    TextMetrics {
                        id: glyphMetrics

                        font: glyph.font
                        text: glyph.text
                    }
                }
            }

            ShellText {
                id: appName

                property string displayedLabel: root.label

                // Centers the capital letters, not the line box (which also
                // holds descender space).
                anchors.verticalCenter: parent.verticalCenter
                anchors.alignWhenCentered: false
                anchors.verticalCenterOffset: height / 2
                    - (baselineOffset - labelMetrics.capitalHeight / 2)
                width: Math.min(root.activeTitleMaximumWidth, implicitWidth)
                text: displayedLabel
                color: theme.text
                elide: Text.ElideRight
                font.pixelSize: appearance.textSize
                font.bold: true

                transform: Translate {
                    id: labelTranslation
                }

                FontMetrics {
                    id: labelMetrics

                    font: appName.font
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
                duration: root.appearance.motion.brief
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: -12
                duration: root.appearance.motion.brief
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
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }

            NumberAnimation {
                target: iconTranslation
                property: "x"
                to: 0
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }
        }
    }

    onLabelChanged: labelTransition.restart()
}
