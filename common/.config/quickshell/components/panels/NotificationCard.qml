import QtQuick
import "../../config" as Config
import "." as Panels
import "NotificationCard.js" as NotificationCard
import "../IconSource.js" as IconSource

// A notification card: one notification in the control center, Android
// style. Tapping it runs its default action, then it is removed and the
// control center closes; one without a default action expands instead.
// Its action buttons run their action and remove it. Swiping it sideways
// past the threshold dismisses it. An ongoing notification (`record.resident`)
// stays after its actions run; only swiping or × removes it.
// `record` is a NotificationHistory item; its `notification` is the live
// Quickshell Notification, or null once the server has let it go.
Item {
    id: root

    required property var appearance
    required property var record
    // Arrived since you last looked.
    property bool highlighted: false
    // Now, for the relative time; the list ticks it while it is shown.
    property double currentTime: Date.now()

    // The image the notification was sent with, or else its app's icon; ""
    // (the bell) when it has neither. An image that won't load falls back to
    // the app icon, and an icon that won't load to the bell.
    property bool imageFailed: false
    readonly property bool showsImage: !!record.image && !imageFailed
    readonly property string iconSource: showsImage ? record.image
        : record.appIcon ? IconSource.forName(record.appIcon) : ""
    readonly property var actions: record.notification ? record.notification.actions : []
    readonly property var buttonActions: NotificationCard.buttonActions(actions)
    // Showing the full body.
    property bool expanded: false
    // How far the card has been dragged sideways.
    property alias swipeOffset: face.x

    // The card is done with: remove it from the history.
    signal dismissed()
    // The control center should close (a default action ran).
    signal closeRequested()

    objectName: "notificationCard"
    implicitHeight: face.height

    // A tap on the card, from its TapHandler.
    function tap() {
        const action = NotificationCard.defaultAction(root.actions);
        if (action) {
            action.invoke();
            if (!root.record.resident)
                root.dismissed();
            root.closeRequested();
        } else {
            root.expanded = !root.expanded;
        }
    }

    // One of the action buttons was pressed.
    function invokeAction(action) {
        action.invoke();
        if (!root.record.resident)
            root.dismissed();
    }

    // Letting go of a sideways drag: past the threshold the card slides out
    // and is dismissed, otherwise it snaps back (SwipeToDismiss).
    function swipeReleased() {
        swipe.letGo();
    }

    function relativeTime(timestamp) {
        const elapsedSeconds = Math.max(0, Math.floor((currentTime - timestamp) / 1000));

        if (elapsedSeconds < 60)
            return "now";
        if (elapsedSeconds < 3600)
            return Math.floor(elapsedSeconds / 60) + "m";
        if (elapsedSeconds < 86400)
            return Math.floor(elapsedSeconds / 3600) + "h";
        return Math.floor(elapsedSeconds / 86400) + "d";
    }

    Config.Theme {
        id: theme
    }

    Rectangle {
        id: face

        width: root.width
        height: content.implicitHeight + 24
        radius: root.appearance.radius
        opacity: swipe.swipeOpacity
        color: cardHover.hovered ? theme.surfaceHover
            : root.highlighted ? Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.12)
            : theme.backgroundSecondary
        border.width: root.highlighted ? 1 : 0
        border.color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.35)

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        Behavior on height {
            NumberAnimation {
                duration: root.appearance.motion.medium
                easing.type: root.appearance.motion.easing
            }
        }

        HoverHandler {
            id: cardHover
        }

        Panels.SwipeToDismiss {
            id: swipe

            target: face
            motion: root.appearance.motion
            swipeWidth: root.width
            onSwiped: root.dismissed()
        }

        TapHandler {
            // A tap on one of the card's own buttons is that button's.
            onTapped: eventPoint => {
                const onButton = [dismissButton, expandButton, actionButtons].some(control => {
                    const point = face.mapToItem(control, eventPoint.position.x, eventPoint.position.y);
                    return control.visible && control.contains(point);
                });
                if (!onButton)
                    root.tap();
            }
        }

        Rectangle {
            id: iconFrame

            x: 12
            y: 12
            width: 36
            height: 36
            radius: width / 2
            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.16)
            clip: true

            Image {
                id: iconImage

                readonly property bool showsImage: root.showsImage

                anchors.fill: parent
                anchors.margins: showsImage ? 0 : 6
                source: root.iconSource
                sourceSize.width: 72
                sourceSize.height: 72
                fillMode: showsImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                asynchronous: true
                onStatusChanged: {
                    if (status === Image.Error && showsImage)
                        root.imageFailed = true;
                }
            }

            Panels.Text {
                anchors.centerIn: parent
                visible: iconImage.status !== Image.Ready
                text: "󰂚"
                color: root.highlighted ? theme.accent : theme.textMuted
                font.pixelSize: 18
            }
        }

        // The fallback for swiping: shown while the card is hovered.
        Panels.PopupButton {
            id: dismissButton

            objectName: "dismissButton"
            appearance: root.appearance
            visible: cardHover.hovered
            x: 2
            y: 2
            z: 1
            width: 20
            height: 20
            radius: width / 2
            color: hovered ? theme.surfaceHover : theme.surface
            border.width: 1
            border.color: theme.border
            label: "󰅖"
            labelColor: theme.textMuted
            labelSize: 12
            onActivated: root.dismissed()
        }

        Column {
            id: content

            x: iconFrame.x + iconFrame.width + 12
            y: 12
            width: face.width - x - 12
            spacing: 3

            Item {
                width: parent.width
                height: titleLine.implicitHeight

                Panels.Text {
                    id: titleLine

                    anchors.left: parent.left
                    anchors.right: meta.left
                    anchors.rightMargin: 8
                    text: root.record.summary || "Notification"
                    color: theme.text
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize
                    font.bold: true
                }

                Row {
                    id: meta

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        visible: root.record.count > 1
                        width: 24
                        height: 18
                        radius: 9
                        color: theme.accent

                        Panels.Text {
                            anchors.centerIn: parent
                            text: root.record.count
                            color: theme.background
                            font.pixelSize: root.appearance.textSize - 3
                        }
                    }

                    Panels.Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.relativeTime(root.record.timestamp)
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 3
                    }

                    // Expands the full body; only there while it doesn't fit.
                    Panels.PopupButton {
                        id: expandButton

                        objectName: "expandButton"
                        appearance: root.appearance
                        visible: root.expanded || bodyText.truncated
                        width: 24
                        height: 20
                        label: root.expanded ? "󰅃" : "󰅀"
                        labelColor: theme.textMuted
                        onActivated: root.expanded = !root.expanded
                    }
                }
            }

            Panels.Text {
                id: bodyText

                width: parent.width
                visible: text !== ""
                text: root.record.body
                color: theme.textMuted
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: root.expanded ? 1000 : 2
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 2
            }

            Item {
                width: 1
                height: 4
                visible: root.buttonActions.length > 0
            }

            Flow {
                id: actionButtons

                width: parent.width
                spacing: 6
                visible: root.buttonActions.length > 0

                Repeater {
                    model: root.buttonActions

                    delegate: Panels.PopupButton {
                        id: actionButton

                        required property var modelData

                        objectName: "notificationActionButton"
                        appearance: root.appearance
                        width: Math.min(160, actionMetrics.width + 24)
                        height: 28
                        color: hovered ? theme.accentHover : Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)
                        label: modelData.text
                        labelColor: hovered ? theme.background : theme.accent
                        labelSize: root.appearance.textSize - 2
                        onActivated: root.invokeAction(modelData)

                        TextMetrics {
                            id: actionMetrics

                            text: actionButton.label
                            font.family: theme.fontFamily
                            font.pixelSize: actionButton.labelSize
                        }
                    }
                }
            }
        }
    }
}
