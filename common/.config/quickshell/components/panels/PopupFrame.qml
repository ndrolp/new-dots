import Quickshell
import QtQuick
import "../../config" as Config
import "PopupPlacement.js" as PopupPlacement

// The frame every popup shares: the window placed next to the bar element
// that opened it, hosting the popup surface. A popup only puts its contents
// inside; the window is as tall as they are unless the popup says otherwise.
// On an opaque bar the popup is attached: it hangs from the bar's bottom edge
// in the bar's own color and opacity. On a transparent bar it floats below.
PopupWindow {
    id: frame

    // The popup's name, as the bar element that opens it knows it.
    required property string popup
    required property var appearance
    required property var barWindow
    // The bar content; places popups of center elements under them.
    property var anchorProvider: null
    property bool open: false
    // Where the popup opens when it isn't under its element: "left" or "right".
    property string edge: "right"
    // Decided by the bar profile of this bar's monitor.
    readonly property bool attached: PopupPlacement.attached(appearance)
    // Room around a floating surface inside the window.
    readonly property real inset: 12
    // How far the curved corners joining an attached popup to the bar reach.
    readonly property real joinRadius: 6
    readonly property var room: PopupPlacement.room({
        attached: attached,
        inset: inset,
        joinRadius: joinRadius
    })
    property alias reveal: surface.reveal
    default property alias contents: surface.contents
    // Hidden while still open, e.g. after losing focus.
    signal dismissed()

    readonly property bool nearTrigger: anchorProvider ? anchorProvider.popupNearTrigger(popup) : false

    function trigger() {
        const element = nearTrigger ? anchorProvider.popupTrigger(popup) : null;
        return element ? { x: anchorProvider.x + element.x, width: element.width } : null;
    }

    grabFocus: true
    visible: reveal > 0
    onVisibleChanged: {
        if (!visible && open)
            dismissed();
    }
    anchor.window: barWindow
    anchor.rect.x: PopupPlacement.x({
        popupWidth: implicitWidth,
        barWidth: barWindow.width,
        padding: appearance.horizontalPadding,
        nearTrigger: nearTrigger,
        trigger: trigger(),
        edge: edge
    })
    anchor.rect.y: PopupPlacement.y({
        barHeight: appearance.barHeight,
        spacing: appearance.spacing,
        nearTrigger: nearTrigger,
        attached: attached,
        content: anchorProvider ? { y: anchorProvider.y, height: anchorProvider.height } : null
    })
    color: "transparent"

    implicitHeight: surface.implicitHeight + room.top + room.bottom

    Config.Theme {
        id: theme
    }

    PopupSurface {
        id: surface

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: frame.room.side
        anchors.rightMargin: frame.room.side
        anchors.topMargin: frame.room.top
        height: implicitHeight
        open: frame.open
        attached: frame.attached
        joinRadius: frame.joinRadius
        radius: frame.appearance.radius
        // The bar's own color and opacity, so an attached popup looks like
        // part of the bar.
        fillColor: frame.attached
            ? Qt.rgba(theme.background.r, theme.background.g, theme.background.b,
                frame.appearance.barOpacity / 100)
            : theme.surface
    }
}
