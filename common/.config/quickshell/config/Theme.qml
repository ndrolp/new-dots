import QtQuick
import "ColorschemeColors.js" as ColorschemeColors

// The shell's look: its font and radius, and the active colorscheme's 16
// colours, which change in place when a colorscheme is applied.
QtObject {
    readonly property string fontFamily: "GeistMono Nerd Font Propo"
    readonly property int radius: 8

    readonly property var colorscheme: ColorschemeColors.shared()

    readonly property color background: colorscheme.colours.background
    readonly property color backgroundSecondary: colorscheme.colours.backgroundSecondary
    readonly property color surface: colorscheme.colours.surface
    readonly property color surfaceHover: colorscheme.colours.surfaceHover
    readonly property color border: colorscheme.colours.border
    readonly property color accent: colorscheme.colours.accent
    readonly property color accentHover: colorscheme.colours.accentHover
    readonly property color green: colorscheme.colours.green
    readonly property color red: colorscheme.colours.red
    readonly property color orange: colorscheme.colours.orange
    readonly property color yellow: colorscheme.colours.yellow
    readonly property color purple: colorscheme.colours.purple
    readonly property color blue: colorscheme.colours.blue
    readonly property color text: colorscheme.colours.text
    readonly property color textMuted: colorscheme.colours.textMuted
    readonly property color textDisabled: colorscheme.colours.textDisabled
}
