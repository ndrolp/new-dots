import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "." as Panels
import "PopupPlacement.js" as PopupPlacement

// The Control center: quick toggles and sliders, centered at the top of the
// focused monitor. Decided per monitor from that bar's profile, it hangs from
// an opaque bar in the bar's color and opacity, like an attached popup, and
// floats below a transparent one. Its controls are ControlCenterBody; this
// window only places them, takes the keyboard and closes on Escape or a
// click outside.
Variants {
    id: root

    required property var appearance
    required property var monitors
    required property var workspaceService
    required property var clipboardHistory
    required property var screenCapture
    required property var systemMonitor
    required property var keepAwake
    // The shell's night light (services/NightLight.qml).
    required property var nightLight
    property bool open: false

    signal closeRequested()
    signal audioSinksRequested()
    signal clipboardRequested()
    signal powerMenuRequested()
    signal screenCaptureRequested()

    model: Quickshell.screens

    delegate: PanelWindow {
        id: controlCenter

        required property var modelData
        readonly property var monitor: Hyprland.monitorFor(modelData)
        readonly property bool focusedMonitor: Hyprland.focusedWorkspace
            && Hyprland.focusedWorkspace.monitor && monitor
            && Hyprland.focusedWorkspace.monitor.name === monitor.name
        // Open on the focused monitor; the window stays up while it closes.
        readonly property bool shown: root.open && focusedMonitor
        readonly property string monitorDescription: root.workspaceService.monitorDescriptionForScreen(modelData)
        readonly property string profileName: root.monitors.barProfileFor(monitorDescription)
        // This monitor's bar, as its popups see it.
        property var barAppearance: QtObject {
            property int barHeight: root.appearance.barProfileValue(controlCenter.profileName, "barHeight")
            property int spacing: root.appearance.barProfileValue(controlCenter.profileName, "spacing")
            property int radius: root.appearance.barProfileValue(controlCenter.profileName, "radius")
            property int textSize: root.appearance.barProfileValue(controlCenter.profileName, "textSize")
            property int transparentBarTopMargin: root.appearance.barProfileValue(controlCenter.profileName, "transparentBarTopMargin")
            property bool transparentBarSlanted: root.appearance.barProfileValue(controlCenter.profileName, "transparentBarSlanted")
            property bool barTransparent: root.appearance.barProfileValue(controlCenter.profileName, "barTransparent")
            property int barOpacity: root.appearance.barProfileValue(controlCenter.profileName, "barOpacity")
            property var motion: root.appearance.motion
        }
        // The bar window's height, as the bar computes it.
        readonly property int totalBarHeight: barAppearance.barHeight
            + (barAppearance.barTransparent && !barAppearance.transparentBarSlanted
                ? barAppearance.transparentBarTopMargin : 0)
        readonly property var placement: PopupPlacement.controlCenter({
            barVisible: root.monitors.barVisible(monitorDescription),
            barTransparent: barAppearance.barTransparent,
            barHeight: totalBarHeight,
            spacing: barAppearance.spacing
        })

        screen: modelData
        visible: surface.reveal > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.namespace: "ndro-shell-control-center"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        function close() {
            root.closeRequested();
        }

        onShownChanged: {
            if (shown)
                keyboardFocus.forceActiveFocus();
        }

        Item {
            id: keyboardFocus

            anchors.fill: parent
            focus: controlCenter.shown
            Keys.onEscapePressed: controlCenter.close()

            // A click outside the Control center closes it.
            TapHandler {
                enabled: controlCenter.shown
                onTapped: controlCenter.close()
            }
        }

        // Keeps clicks on the Control center's own background from closing it.
        MouseArea {
            x: surface.x
            y: surface.y
            width: surface.width
            height: surface.unfoldedHeight
        }

        PopupSurface {
            id: surface

            anchors.horizontalCenter: parent.horizontalCenter
            y: controlCenter.placement.y
            width: Math.min(parent.width - 48, 540)
            height: implicitHeight
            open: controlCenter.shown
            enabled: controlCenter.shown
            attached: controlCenter.placement.attached
            radius: controlCenter.barAppearance.radius
            barOpacity: controlCenter.barAppearance.barOpacity
            motion: controlCenter.barAppearance.motion

            Panels.ControlCenterBody {
                width: parent.width
                appearance: root.appearance
                barAppearance: controlCenter.barAppearance
                clipboardHistory: root.clipboardHistory
                screenCapture: root.screenCapture
                systemMonitor: root.systemMonitor
                keepAwake: root.keepAwake
                nightLight: root.nightLight
                shown: controlCenter.shown

                onCloseRequested: controlCenter.close()
                onAudioSinksRequested: root.audioSinksRequested()
                onClipboardRequested: root.clipboardRequested()
                onPowerMenuRequested: root.powerMenuRequested()
                onScreenCaptureRequested: root.screenCaptureRequested()
            }
        }
    }
}
