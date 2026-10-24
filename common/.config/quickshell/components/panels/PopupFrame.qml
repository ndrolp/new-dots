import Quickshell
import QtQuick
import QtQuick.Effects
import "../../config" as Config
import "PopupPlacement.js" as PopupPlacement

// The frame every popup shares: the window placed next to the bar element
// that opened it, the surface with its border and shadow, and the opening and
// closing animation. A popup only puts its contents inside.
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
    property int revealDuration: 180
    // How far the surface slides down while opening.
    property real revealOffset: 12
    // The scale the surface grows from while opening.
    property real revealScale: 1
    property bool clipContents: false
    property real reveal: open ? 1 : 0
    default property alias contents: surface.data
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

    Behavior on reveal {
        NumberAnimation {
            duration: frame.revealDuration
            easing.type: Easing.OutCubic
        }
    }

    Config.Theme {
        id: theme
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        anchors.margins: 12
        radius: frame.appearance.radius
        color: theme.surface
        opacity: frame.reveal
        border.color: theme.border
        border.width: 1
        clip: frame.clipContents
        transform: Translate { y: -frame.revealOffset * (1 - frame.reveal) }
        scale: frame.revealScale + (1 - frame.revealScale) * frame.reveal
        transformOrigin: Item.TopRight

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#73000000"
            shadowBlur: 0.65
            shadowVerticalOffset: 6
        }

        Behavior on scale {
            enabled: frame.revealScale !== 1

            NumberAnimation {
                duration: frame.revealDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
