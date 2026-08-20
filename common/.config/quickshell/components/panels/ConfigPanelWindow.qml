import Quickshell
import QtQuick

PopupWindow {
    id: root

    required property var appearance
    required property var monitors
    required property var wallpapers
    property bool open: false
    property var targetWindow
    property real reveal: open ? 1 : 0

    signal closeRequested()

    onVisibleChanged: {
        if (!visible && open)
            closeRequested();
    }

    visible: reveal > 0 && targetWindow !== null
    anchor.window: root.targetWindow
    anchor.rect.x: root.appearance.horizontalPadding
    anchor.rect.y: root.appearance.barHeight + root.appearance.spacing
    color: "transparent"
    grabFocus: true
    implicitWidth: configPanel.implicitWidth + 24
    implicitHeight: configPanel.implicitHeight + 24

    Behavior on reveal {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ConfigPanel {
        id: configPanel

        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 12 - 16 * (1 - root.reveal)
        opacity: root.reveal
        appearance: root.appearance
        monitors: root.monitors
        wallpapers: root.wallpapers

        onCloseRequested: root.closeRequested()
    }
}
