import Quickshell
import Quickshell.Hyprland
import QtQuick
import "PopupGrab.js" as PopupGrab
import "PopupPlacement.js" as PopupPlacement

// The frame every popup shares: the window placed next to the bar element
// that opened it, hosting the popup surface. A popup only puts its contents
// inside; the window is as tall as they are unless the popup says otherwise.
// On an opaque or docked bar the popup is attached: it hangs from the bar in the
// bar's own color and opacity. On any other transparent bar it floats clear of
// it. A focus grab, not the compositor's popup grab, closes it on a click
// outside it and its bar, so the window stays up for the close animation.
PopupWindow {
    id: frame

    // The popup's name, as the bar element that opens it knows it.
    required property string popup
    required property var appearance
    required property var barWindow
    // The bar content; places popups at the bar element that opened them.
    property var anchorProvider: null
    property bool open: false
    // Where the popup opens when its element isn't on the bar: "left" or
    // "right", which on a side bar mean its top and bottom.
    property string edge: "right"
    // The screen edge the bar sits on.
    readonly property string barPosition: appearance.barPosition
    // Decided by the bar profile of this bar's monitor.
    readonly property bool attached: PopupPlacement.attached(appearance)
    // Room around a floating surface inside the window.
    readonly property real inset: 12
    // How far the curved corners joining an attached popup to the bar reach.
    readonly property real joinRadius: 6
    // Where the window opens in the bar window.
    readonly property var placed: PopupPlacement.position({
        barPosition: barPosition,
        popupWidth: implicitWidth,
        popupHeight: implicitHeight,
        restingHeight: restingHeight,
        window: { width: barWindow.width, height: barWindow.height },
        barHeight: appearance.barHeight,
        padding: appearance.horizontalPadding,
        radius: appearance.radius,
        spacing: appearance.spacing,
        attached: attached,
        trigger: anchorProvider ? PopupPlacement.triggerSpan(barPosition, anchorProvider,
            anchorProvider.popupTrigger(popup)) : null,
        edge: edge,
        content: anchorProvider ? {
            x: anchorProvider.x,
            y: anchorProvider.y,
            width: anchorProvider.width,
            height: anchorProvider.height
        } : null
    })
    // The stretch of the bar the window spans, as plain numbers so that only a
    // real move is news to the bar.
    readonly property real placedStart: placed.start
    readonly property real placedEnd: placed.end
    readonly property var room: PopupPlacement.room({
        barPosition: barPosition,
        attached: attached,
        inset: inset,
        joinRadius: joinRadius
    })
    property alias reveal: surface.reveal
    // While a popup resizes itself in an animation it holds the window tall
    // enough for contents of this height (the larger end), so the window is
    // resized once instead of every frame; 0 lets it follow the surface.
    property real heldHeight: 0
    // The window's height without that hold.
    readonly property real restingHeight: surface.implicitHeight + room.top + room.bottom
    default property alias contents: surface.contents
    // Closed from outside while still open: a click outside it and its bar,
    // another grab taking over, or its bar hiding.
    signal dismissed()

    visible: reveal > 0
    onVisibleChanged: {
        if (!visible && open)
            dismissed();
    }
    anchor.window: barWindow
    anchor.rect.x: placed.x
    anchor.rect.y: placed.y
    color: "transparent"

    implicitHeight: Math.max(restingHeight, heldHeight + surface.padding * 2 + room.top + room.bottom)

    HyprlandFocusGrab {
        id: focusGrab

        windows: PopupGrab.windows(frame, frame.barWindow, focusGrab.active)
        // Not `visible`, which turns true before the popup has a surface: the
        // grab would start with nothing to hold, and never activate.
        active: frame.open && frame.backingWindowVisible
        onCleared: frame.dismissed()
    }

    PopupSurface {
        id: surface

        // A window held taller than the surface keeps it against the bar, or
        // on a side bar where it would rest.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: frame.barPosition === "bottom" ? undefined : parent.top
        anchors.bottom: frame.barPosition === "bottom" ? parent.bottom : undefined
        anchors.leftMargin: frame.room.left
        anchors.rightMargin: frame.room.right
        anchors.topMargin: frame.room.top + frame.placed.surfaceShift
        anchors.bottomMargin: frame.room.bottom
        height: implicitHeight
        barPosition: frame.barPosition
        open: frame.open
        attached: frame.attached
        joinRadius: frame.joinRadius
        radius: frame.appearance.radius
        barOpacity: frame.appearance.barOpacity
        motion: frame.appearance.motion
    }
}
