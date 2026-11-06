import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../components/panels" as Panels

// The toast for an unknown combination, on the focused monitor. A choice goes through the quick
// switch's countdown; going away unanswered saves nothing. MonitorSetups.qml says when it's up.
Scope {
    id: root

    required property var appearance
    required property var monitorSetups
    required property var settings
    required property var bar

    // Displays, on the focused monitor's bar, or any bar if it has none.
    function arrange() {
        const bars = root.bar.bars().filter(candidate => candidate.visible);
        const focused = root.bar.focusedMonitor();
        const target = bars.filter(candidate => candidate.monitor === focused)[0] || bars[0];
        if (target !== undefined)
            root.settings.openSectionOn("Monitors", target.window.screen, target.window);
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            screen: modelData
            visible: root.monitorSetups.offeringChoices && monitor !== null
                && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === monitor.name
            anchors.top: true
            margins.top: 48
            implicitWidth: card.width
            implicitHeight: card.height
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "ndro-shell-monitor-toast"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Panels.MonitorToastCard {
                id: card

                appearance: root.appearance
                choices: root.monitorSetups.quickSwitchChoices
                onChosen: choice => {
                    root.monitorSetups.dismissToast();
                    root.monitorSetups.quickSwitch(choice);
                }
                onArrangeAsked: {
                    root.monitorSetups.dismissToast();
                    root.arrange();
                }
                onDismissAsked: root.monitorSetups.dismissToast()
            }
        }
    }

    Timer {
        interval: 20000
        running: root.monitorSetups.offeringChoices
        onTriggered: root.monitorSetups.dismissToast()
    }
}
