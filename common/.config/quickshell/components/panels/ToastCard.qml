import QtQuick
import "../../config" as Config
import "." as Panels
import "NotificationCard.js" as NotificationCard
import "../IconSource.js" as IconSource

// The card a new notification shows as: a toast, or inside the capsule with
// notifications in the capsule on. Icon or image, app, summary and body, its
// actions as buttons and, when its app asks for one, an inline reply. It
// shows for the toast timeout (NotificationCard.toastTimeout), its progress
// as a line along its foot; a critical one stays until it is dismissed.
// Tapping it runs its default action; × only ends it. The notification itself
// lives on in the control center.
Item {
    id: root

    // { radius, textSize, motion }: a bar profile's sizes and the motion.
    required property var appearance
    // The live Quickshell Notification.
    required property var notification
    // Counting down its timeout: off while it isn't shown, or while a reply
    // is being written.
    property bool running: true
    // How many more wait behind it in the capsule, shown as "+N"; 0 for none.
    property int waiting: 0
    // Draws its own surface, as a toast does; inside the capsule the capsule
    // is its surface.
    property bool framed: true
    // Its timeout, in ms; 0 when it stays until dismissed.
    readonly property int timeout: NotificationCard.toastTimeout({
        expireTimeout: notification ? notification.expireTimeout : -1,
        // NotificationUrgency.Critical.
        critical: !!notification && notification.urgency === 2
    })
    readonly property var actions: notification ? notification.actions : []
    readonly property var buttonActions: NotificationCard.buttonActions(actions)
    readonly property bool hasInlineReply: !!notification && notification.hasInlineReply
    // Writing a reply, from the press on its field on: the window holding the
    // card takes the keyboard meanwhile, and the timeout waits.
    property bool replyStarted: false
    readonly property bool replying: replyStarted || replyField.activeFocus
    // How much of its timeout is left, from 1 down to 0.
    property real lifetimeProgress: 1

    // Another notification takes the card: its timeout starts afresh.
    onNotificationChanged: {
        lifetimeProgress = 1;
        stopReplying();
        replyField.text = "";
    }

    // The card is done with: its timeout ran out, it was tapped, closed,
    // acted on or replied to.
    signal ended()

    implicitHeight: content.implicitHeight + 28

    // A tap on the card: runs its default action, if it has one.
    function tap() {
        const action = NotificationCard.defaultAction(root.actions);
        if (action)
            action.invoke();
        root.ended();
    }

    // The ×: ends it without running anything.
    function close() {
        root.ended();
    }

    // One of the action buttons was pressed.
    function invokeAction(action) {
        action.invoke();
        root.ended();
    }

    // Sends `text` as the inline reply; an empty reply sends nothing.
    function sendReply(text) {
        if (text.trim() === "")
            return;
        root.notification.sendInlineReply(text);
        root.stopReplying();
        root.ended();
    }

    // Leaves the reply field: the keyboard goes back and the timeout goes on.
    function stopReplying() {
        root.replyStarted = false;
        replyField.focus = false;
    }

    Config.Theme {
        id: theme
    }

    Timer {
        interval: 50
        running: root.running && root.timeout > 0 && !root.replying
        repeat: true
        onTriggered: {
            root.lifetimeProgress = Math.max(0, root.lifetimeProgress - interval / root.timeout);
            if (root.lifetimeProgress === 0)
                root.ended();
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        radius: root.appearance.radius
        color: theme.surface
        border.color: theme.border
        border.width: 1
    }

    TapHandler {
        // A tap on one of the card's own controls is that control's.
        onTapped: eventPoint => {
            const onControl = [closeButton, actionButtons, replyRow].some(control => {
                const point = root.mapToItem(control, eventPoint.position.x, eventPoint.position.y);
                return control.visible && control.contains(point);
            });
            if (!onControl)
                root.tap();
        }
    }

    Row {
        id: content

        x: 14
        y: 14
        width: parent.width - 28
        spacing: 12

        Rectangle {
            id: iconFrame

            width: 56
            height: 56
            radius: root.appearance.radius
            color: theme.accent

            Image {
                id: iconImage

                anchors.fill: parent
                anchors.margins: 2
                source: !root.notification ? ""
                    : root.notification.image !== "" ? root.notification.image
                    : root.notification.appIcon !== "" ? IconSource.forName(root.notification.appIcon) : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Panels.ShellText {
                anchors.centerIn: parent
                visible: iconImage.status !== Image.Ready
                text: "󰂚"
                color: theme.background
                font.pixelSize: 20
                font.bold: true
            }
        }

        Column {
            width: parent.width - iconFrame.width - parent.spacing
            spacing: 3

            Item {
                width: parent.width
                height: appLine.implicitHeight

                Panels.ShellText {
                    id: appLine

                    anchors.left: parent.left
                    anchors.right: waitingCount.left
                    anchors.rightMargin: 8
                    text: root.notification ? root.notification.appName : ""
                    color: theme.textMuted
                    elide: Text.ElideRight
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }

                // How many more wait in the capsule, and room for the ×.
                Panels.ShellText {
                    id: waitingCount

                    anchors.right: parent.right
                    anchors.rightMargin: 30
                    visible: root.waiting > 0
                    width: visible ? implicitWidth : 0
                    text: "+" + root.waiting
                    color: theme.accent
                    font.pixelSize: root.appearance.textSize - 2
                    font.bold: true
                }
            }

            Panels.ShellText {
                width: parent.width
                text: root.notification ? root.notification.summary : ""
                color: theme.text
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize + 1
                font.bold: true
            }

            Panels.ShellText {
                width: parent.width
                visible: text !== ""
                text: root.notification ? root.notification.body : ""
                color: theme.textMuted
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: root.appearance.textSize - 1
                font.bold: true
            }

            Item {
                width: 1
                height: 4
                visible: actionButtons.visible || replyRow.visible
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

                        objectName: "toastActionButton"
                        appearance: root.appearance
                        width: Math.min(160, actionMetrics.width + 24)
                        height: 28
                        color: hovered ? theme.accentHover
                            : Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.18)
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

            // The inline reply, when its app asks for one: Enter sends it.
            Row {
                id: replyRow

                width: parent.width
                spacing: 6
                visible: root.hasInlineReply

                Panels.PopupTextField {
                    id: replyField

                    objectName: "toastReplyField"
                    appearance: root.appearance
                    width: parent.width - sendButton.width - parent.spacing
                    height: 28
                    placeholderText: root.notification && root.notification.inlineReplyPlaceholder !== ""
                        ? root.notification.inlineReplyPlaceholder : "Reply"
                    onPressed: root.replyStarted = true
                    onAccepted: root.sendReply(text)
                    Keys.onEscapePressed: root.stopReplying()
                }

                Panels.PopupButton {
                    id: sendButton

                    appearance: root.appearance
                    width: 36
                    height: 28
                    label: "󰒊"
                    labelColor: theme.accent
                    onActivated: root.sendReply(replyField.text)
                }
            }
        }
    }

    Rectangle {
        id: closeButton

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 24
        height: 24
        radius: root.appearance.radius
        color: closeHover.hovered ? theme.surfaceHover : theme.backgroundSecondary

        Behavior on color {
            ColorAnimation { duration: root.appearance.motion.short }
        }

        HoverHandler {
            id: closeHover
        }

        Panels.ShellText {
            anchors.centerIn: parent
            text: "󰅖"
            color: theme.textMuted
            font.pixelSize: 15
            font.bold: true
        }

        TapHandler {
            onTapped: root.close()
        }
    }

    // How much of its timeout is left; none on one that stays.
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        visible: root.timeout > 0
        width: parent.width * root.lifetimeProgress
        height: 3
        radius: root.appearance.radius
        color: theme.accent
    }
}
