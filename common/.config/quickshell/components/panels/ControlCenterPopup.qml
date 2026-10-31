import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import "MediaCard.js" as MediaCard

// The control center: the popup of the bell bar element (saved id
// "notifications"). Collapsed, it shows the tile row above today's
// notifications; expanded, every control in their place
// (ControlCenterLayout), and the audio output tile opens the audio output
// subpage. With the control center plugin off it is notifications only.
// The ongoing notifications (the media card while a player is active, and
// the `resident` notifications) stay on top in both stages.
BarPopup {
    id: root

    required property var notificationHistory
    required property var screenCapture
    required property var clipboardHistory
    required property var systemMonitor
    required property var keepAwake
    required property var nightLight
    property bool controlsEnabled: true
    // The stage the next opening takes, "collapsed" or "expanded"; changed
    // while open, it switches to it. The stage the open control center
    // switches to by itself (the handle, the audio output tile) goes back up
    // as `popups.controlCenterStageSwitched`, so SUPER+C/SUPER+N know it.
    property string requestedStage: "collapsed"

    popup: "controlCenter"
    implicitWidth: 424

    ControlCenterLayout {
        id: layout

        width: parent.width
        appearance: root.appearance
        open: root.open
        controlsEnabled: root.controlsEnabled
        requestedStage: root.requestedStage

        onStageChanged: {
            if (root.open)
                root.popups.controlCenterStageSwitched(stage);
        }

        ongoing: Component {
            ControlCenterOngoing {
                width: layout.width
                appearance: root.appearance
                notificationHistory: root.notificationHistory
                player: MediaCard.activePlayer(Mpris.players.values)
                open: root.open
                highlightedIds: layout.notificationsItem
                    ? layout.notificationsItem.highlightedIds : []

                onCloseRequested: root.popups.popupClosed(root.popup)
            }
        }

        controls: Component {
            ControlCenterBody {
                width: layout.width
                barAppearance: root.appearance
                clipboardHistory: root.clipboardHistory
                screenCapture: root.screenCapture
                systemMonitor: root.systemMonitor
                keepAwake: root.keepAwake
                nightLight: root.nightLight
                // Any tile can sit in the collapsed row, so it reads the power
                // profile, Caps Lock and the clipboard whenever it is open.
                shown: root.open
                expanded: layout.expanded

                onCloseRequested: root.popups.popupClosed(root.popup)
                onDoNotDisturbToggled: root.popups.doNotDisturbToggled()
                onAudioOutputsRequested: layout.openAudioOutputs()
                onClipboardRequested: root.popups.clipboardRequested()
                onPowerMenuRequested: root.popups.powerMenuRequested()
                onScreenCaptureRequested: root.popups.screenCaptureRequested()
                onTileSettingsRequested: root.popups.controlCenterSettingsRequested()
            }
        }

        // Choosing an output switches to it with the same OSD as the audio
        // output selector; the control center stays open.
        audioOutputs: Component {
            ControlCenterAudioOutputs {
                width: layout.width
                appearance: root.appearance
                outputs: Pipewire.nodes.values.filter(node => node.isSink)
                current: Pipewire.defaultAudioSink

                onOutputChosen: output => {
                    Pipewire.preferredDefaultAudioSink = output;
                    root.popups.audioOutputSelected(output);
                }
                onBackRequested: layout.back()

                // Binds the outputs, so their names and the default are known.
                PwObjectTracker {
                    objects: Pipewire.nodes.values
                }
            }
        }

        notifications: Component {
            ControlCenterNotifications {
                width: layout.width
                appearance: root.appearance
                notificationHistory: root.notificationHistory
                open: root.open

                onCloseRequested: root.popups.popupClosed(root.popup)
            }
        }
    }
}
