import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick
import "MediaCard.js" as MediaCard
import "ControlCenterNames.js" as Names

// The control center: the popup of the bell bar element (saved id
// "notifications"). Collapsed, it shows the tile row above today's
// notifications; expanded, every control in their place
// (ControlCenterLayout), and the audio output tile opens the audio output
// subpage. With the control center plugin off it is notifications only.
// The ongoing notifications (the media card while a player is active, and
// the `resident` notifications) stay on top in both stages.
BarPopup {
    id: root

    // The control center module (modules/ControlCenter.qml): the services
    // it shows, `controlsEnabled` (the plugin), the `stage` (each opening
    // takes it; changed while open, it switches in place), and the panels
    // its tiles open (`openPanel`).
    required property var controlCenter

    popup: Names.controlCenter.popup
    implicitWidth: 424

    ControlCenterLayout {
        id: layout

        width: parent.width
        appearance: root.appearance
        open: root.open
        controlsEnabled: root.controlCenter.controlsEnabled
        requestedStage: root.controlCenter.stage

        // It switched by itself (the handle, the audio output tile): the
        // module keeps the stage, so SUPER+C/SUPER+N know it.
        onStageChanged: {
            if (root.open)
                root.controlCenter.stage = stage;
        }

        ongoing: Component {
            ControlCenterOngoing {
                width: layout.width
                appearance: root.appearance
                notificationHistory: root.controlCenter.notificationHistory
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
                controlCenter: root.controlCenter
                // Any tile can sit in the collapsed row, so it reads the power
                // profile, Caps Lock and the clipboard whenever it is open.
                shown: root.open
                expanded: layout.expanded

                onCloseRequested: root.popups.popupClosed(root.popup)
                onAudioOutputsRequested: layout.openAudioOutputs()
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
                notificationHistory: root.controlCenter.notificationHistory
                open: root.open

                onCloseRequested: root.popups.popupClosed(root.popup)
            }
        }
    }
}
