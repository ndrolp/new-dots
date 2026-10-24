import Quickshell
import QtQuick
import "PopupPlacement.js" as PopupPlacement

// The frame every popup shares: the window placed next to the bar element
// that opened it, hosting the popup surface. A popup only puts its contents
// inside; the window is as tall as they are unless the popup says otherwise.
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
    // Room around the surface inside the window.
    readonly property real inset: 12
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
        content: anchorProvider ? { y: anchorProvider.y, height: anchorProvider.height } : null
    })
    color: "transparent"

    implicitHeight: surface.implicitHeight + inset * 2

    PopupSurface {
        id: surface

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: frame.inset
        height: implicitHeight
        open: frame.open
        radius: frame.appearance.radius
    }
}
