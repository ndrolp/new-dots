import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "." as Panels
import "NotificationPlacement.js" as NotificationPlacement

// The toasts: each new notification shows here as a card
// (NewNotificationCard) for its timeout, unless Do Not Disturb is on or it shows inside the capsule
// instead (CapsuleRouting.notificationTarget). Those a capsule hands back,
// when a popup opens inside it or it hides for a fullscreen window, show here
// afresh.
PanelWindow {
    id: root

    required property var notificationServer
    required property var appearance
    required property var monitors
    required property var workspaceService

    // What the toasts take from a bar profile comes from this monitor's own,
    // not from the one being edited in the settings.
    readonly property string profileName: monitors.barProfileFor(
        workspaceService.monitorDescriptionForScreen(screen))
    readonly property var toastSizes: ({
        spacing: appearance.barProfileValue(profileName, "spacing"),
        horizontalPadding: appearance.barProfileValue(profileName, "horizontalPadding"),
        radius: appearance.barProfileValue(profileName, "radius"),
        textSize: appearance.barProfileValue(profileName, "textSize")
    })
    // What a card takes: those sizes and the motion.
    readonly property var cardAppearance: ({
        radius: toastSizes.radius,
        textSize: toastSizes.textSize,
        motion: appearance.motion
    })
    readonly property var placement: NotificationPlacement.place(
        appearance.notificationPopupLocation, toastSizes)
    // New notifications the capsule shows instead: their toasts don't show.
    property var inCapsule: []
    // The card whose inline reply is being written, which takes the keyboard.
    property var replyingCard: null

    // `notification` shows inside the capsule, not as a toast; called before
    // the server tracks it, so its toast is decided with it.
    function leaveToCapsule(notification) {
        inCapsule = inCapsule.concat([notification]);
    }

    // Shows `notifications` as toasts afresh: the capsule handed them back.
    function showToasts(notifications) {
        for (let index = 0; index < toasts.count; index++) {
            const toast = toasts.itemAt(index);
            if (toast && notifications.indexOf(toast.modelData) !== -1)
                toast.showAgain();
        }
    }

    screen: Quickshell.screens.values.length > 0 ? Quickshell.screens.values[0] : null
    color: "transparent"
    // Normal: the compositor keeps it inside what the monitor's bar leaves free.
    exclusionMode: ExclusionMode.Normal
    implicitWidth: 404
    implicitHeight: notificationList.implicitHeight + 24

    WlrLayershell.namespace: "ndro-shell-notifications"
    // Only while an inline reply is written, from the press on its field.
    WlrLayershell.keyboardFocus: replyingCard !== null ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        item: notificationList
    }

    anchors {
        top: root.placement.anchors.top
        right: root.placement.anchors.right
        bottom: root.placement.anchors.bottom
        left: root.placement.anchors.left
    }

    margins {
        top: root.placement.margins.top
        right: root.placement.margins.right
        bottom: root.placement.margins.bottom
        left: root.placement.margins.left
    }

    Column {
        id: notificationList

        x: 12
        y: 12
        width: root.implicitWidth - 24
        spacing: 8

        // One delegate per notification the server keeps, i.e. per card in
        // the control center; only the toasts still showing are visible.
        Repeater {
            id: toasts

            model: root.notificationServer.trackedNotifications

            delegate: Item {
                id: toast

                required property var modelData
                // A toast shows when its notification arrives, unless do not
                // disturb is on, it shows inside the capsule or it was only
                // sent again after a reload. It hides when its card ends or
                // do not disturb turns on; the notification lives on in the
                // control center until its card leaves the history.
                property bool toastShown: !root.appearance.doNotDisturb
                    && !modelData.lastGeneration && root.inCapsule.indexOf(modelData) === -1
                property real reveal: 0

                function hide() {
                    toastShown = false;
                    card.stopReplying();
                }

                // Handed back by the capsule: shows with its whole timeout.
                function showAgain() {
                    if (root.appearance.doNotDisturb)
                        return;
                    card.lifetimeProgress = 1;
                    toastShown = true;
                }

                visible: toastShown
                width: parent.width
                height: card.implicitHeight
                opacity: reveal

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#73000000"
                    shadowBlur: 0.65
                    shadowVerticalOffset: 6
                }

                transform: Translate {
                    y: -16 * (1 - toast.reveal)
                }

                Component.onCompleted: {
                    // Breaks the binding: the toast's fate is decided once.
                    toastShown = toastShown;
                    root.inCapsule = root.inCapsule.filter(notification => notification !== modelData);
                    reveal = 1;
                }

                Connections {
                    target: root.appearance

                    function onDoNotDisturbChanged() {
                        if (root.appearance.doNotDisturb)
                            toast.hide();
                    }
                }

                Behavior on reveal {
                    NumberAnimation {
                        duration: root.appearance.motion.medium
                        easing.type: root.appearance.motion.easing
                    }
                }

                Panels.NewNotificationCard {
                    id: card

                    width: parent.width
                    appearance: root.cardAppearance
                    notification: toast.modelData
                    running: toast.toastShown
                    onEnded: toast.hide()
                    onReplyingChanged: {
                        if (replying)
                            root.replyingCard = card;
                        else if (root.replyingCard === card)
                            root.replyingCard = null;
                    }
                    Component.onDestruction: {
                        if (root.replyingCard === card)
                            root.replyingCard = null;
                    }
                }
            }
        }
    }
}
