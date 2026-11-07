import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../components/panels" as Panels
import "OpenPopup.js" as OpenPopup

// The toasts about monitors, on the focused monitor: the one for an unknown combination, and failures.
// A choice goes through the quick switch's countdown; going away unanswered saves nothing.
// MonitorSetups.qml says when each is up, and both leave by themselves after 20 seconds.
Scope {
    id: root

    required property var appearance
    required property var monitorSetups
    required property var settings
    required property var bar

    readonly property string notice: monitorSetups.notice
    // A lock screen would hide it, so it waits.
    readonly property bool showingNotice: notice !== "" && !monitorSetups.locked

    // Displays, on the focused monitor's bar, or any bar if it has none.
    function arrange() {
        const window = OpenPopup.focusedBar(root.bar.bars(), root.bar.focusedMonitor());
        if (window !== null)
            root.settings.openSectionOn("Monitors", window.screen, window);
    }

    // More said to an open notice gets the full time.
    onNoticeChanged: {
        if (showingNotice)
            noticeTimer.restart();
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            screen: modelData
            visible: (root.monitorSetups.offeringChoices || root.showingNotice) && monitor !== null
                && Hyprland.focusedMonitor !== null && Hyprland.focusedMonitor.name === monitor.name
            anchors.top: true
            margins.top: 48
            implicitWidth: cards.width
            implicitHeight: cards.height
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "ndro-shell-monitor-toast"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: cards

                spacing: 8

                Panels.MonitorNoticeCard {
                    visible: root.showingNotice
                    appearance: root.appearance
                    message: root.notice
                    onDismissAsked: root.monitorSetups.dismissNotice()
                }

                Panels.MonitorToastCard {
                    visible: root.monitorSetups.offeringChoices
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
    }

    Timer {
        interval: 20000
        running: root.monitorSetups.offeringChoices
        onTriggered: root.monitorSetups.dismissToast()
    }

    Timer {
        id: noticeTimer

        interval: 20000
        running: root.showingNotice
        onTriggered: root.monitorSetups.dismissNotice()
    }
}
