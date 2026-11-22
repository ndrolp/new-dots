import QtQuick
import "ColorschemeColors.js" as ColorschemeColors
import "Font.js" as Font

// The shell's look: its font and radius, and the active colorscheme's 16
// colours, which change in place when a colorscheme is applied.
QtObject {
    readonly property string fontFamily: Font.family
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

    // The surface at 85% opacity, for a panel over a desktop the compositor
    // blurs behind it (a Hyprland layer rule on its namespace). The text keeps
    // its full colour, so it stays as readable as on the opaque surface.
    readonly property color translucentSurface: Qt.rgba(surface.r, surface.g, surface.b, 0.85)

    // The fill under a briefly highlighted item, e.g. the setting a settings
    // search lands on: a faint wash of the accent, with the accent as its border.
    readonly property color highlightFill: Qt.rgba(accent.r, accent.g, accent.b, 0.16)

    // The faint fill a control on a settings card takes while hovered or
    // chosen. The card is filled with surfaceHover at half opacity, so this is
    // surfaceHover, opaque and tinted a fifth of the way toward the accent, to
    // stand out in every colorscheme.
    readonly property color cardHover: Qt.tint(surfaceHover, Qt.rgba(accent.r, accent.g, accent.b, 0.2))
}
