import QtQuick
import "../../config" as Config
import "." as Panels
import "NotificationCard.js" as NotificationCard

// One app's notifications in the control center, under the app's name. Two
// or more collapse into an app stack: the newest notification card with
// "+N more" peeking out under it. Tapping the stack expands it into every
// card of the app ("Show less" collapses it again), and swiping it sideways
// dismisses the whole group. A single notification is a plain card.
// `group` is a NotificationHistory group: { appName, items }, newest first.
// The owner keeps `expanded`, so it outlives the history changing.
Item {
    id: root

    required property var appearance
    required property var group
    // The ids of the notifications that arrived since you last looked.
    property var highlightedIds: []
    // Now, for the cards' relative time.
    property double currentTime: Date.now()
    // Showing every card of the app rather than the stack.
    property bool expanded: false
    readonly property bool stacked: group.items.length > 1
    readonly property bool collapsed: stacked && !expanded
    // How far the collapsed stack has been dragged sideways.
    property alias swipeOffset: stackFace.x

    // A card is done with: remove that notification from the history.
    signal entryDismissed(var id)
    // The collapsed stack was swiped away: remove the whole group.
    signal groupDismissed()
    // A card ran its default action: the control center should close.
    signal closeRequested()
    // The stack was tapped, or "Show less" pressed: flip `expanded`.
    signal expandToggled()

    objectName: stacked ? "notificationStack" : "notificationGroup"
    implicitHeight: content.implicitHeight

    // A tap on the collapsed stack, from its TapHandler.
    function tap() {
        if (root.collapsed)
            root.expandToggled();
    }

    // Letting go of a sideways drag of the collapsed stack: past the
    // threshold it slides out and the group is dismissed, otherwise it snaps
    // back.
    function swipeReleased() {
        if (NotificationCard.swipeDismisses(stackFace.x, root.width)) {
            swipeOut.to = stackFace.x < 0 ? -root.width : root.width;
            swipeOut.restart();
        } else {
            snapBack.restart();
        }
    }

    function highlighted(entry) {
        return root.highlightedIds.indexOf(entry.id) !== -1;
    }

    Config.Theme {
        id: theme
    }

    NumberAnimation {
        id: swipeOut

        target: stackFace
        property: "x"
        duration: root.appearance.motion.medium
        easing.type: root.appearance.motion.easing
        onFinished: root.groupDismissed()
    }

    NumberAnimation {
        id: snapBack

        target: stackFace
        property: "x"
        to: 0
        duration: root.appearance.motion.medium
        easing.type: root.appearance.motion.easing
    }

    Column {
        id: content

        width: root.width
        spacing: 6

        Item {
            width: parent.width
            height: Math.max(appLabel.implicitHeight, showLessButton.visible ? showLessButton.height : 0)

            Panels.PopupLabel {
                id: appLabel

                anchors.left: parent.left
                anchors.right: showLessButton.left
                anchors.verticalCenter: parent.verticalCenter
                appearance: root.appearance
                text: root.group.appName
            }

            Panels.PopupButton {
                id: showLessButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                appearance: root.appearance
                visible: root.stacked && root.expanded
                width: showLessMetrics.width + 20
                height: 22
                label: "Show less"
                labelColor: theme.textMuted
                labelSize: root.appearance.textSize - 2
                onActivated: root.expandToggled()

                TextMetrics {
                    id: showLessMetrics

                    text: showLessButton.label
                    font.family: theme.fontFamily
                    font.pixelSize: showLessButton.labelSize
                }
            }
        }

        // The collapsed stack: the newest card, the next one peeking out
        // under it with "+N more".
        Item {
            id: stackFrame

            visible: root.collapsed
            width: parent.width
            height: visible ? topCard.implicitHeight + 22 : 0

            Item {
                id: stackFace

                width: parent.width
                height: parent.height
                opacity: 1 - Math.min(1, Math.abs(x) / Math.max(1, root.width)) * 0.8

                Rectangle {
                    x: 8
                    width: parent.width - 16
                    height: parent.height
                    radius: root.appearance.radius
                    color: theme.surface
                    border.width: 1
                    border.color: theme.border

                    Panels.Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 22
                        verticalAlignment: Text.AlignVCenter
                        text: "+" + (root.group.items.length - 1) + " more"
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                // The stack takes the taps and swipes, not the card.
                Panels.NotificationCard {
                    id: topCard

                    width: parent.width
                    enabled: false
                    appearance: root.appearance
                    entry: root.group.items[0]
                    highlighted: root.group.items.some(entry => root.highlighted(entry))
                    currentTime: root.currentTime
                }

                DragHandler {
                    target: stackFace
                    xAxis.enabled: true
                    yAxis.enabled: false
                    onActiveChanged: {
                        if (!active)
                            root.swipeReleased();
                    }
                }

                TapHandler {
                    onTapped: root.tap()
                }
            }
        }

        // Every card of the app: a single notification, or an expanded stack.
        Column {
            visible: !root.collapsed
            width: parent.width
            spacing: 6

            Repeater {
                model: root.collapsed ? [] : root.group.items

                delegate: Panels.NotificationCard {
                    required property var modelData

                    width: root.width
                    appearance: root.appearance
                    entry: modelData
                    highlighted: root.highlighted(modelData)
                    currentTime: root.currentTime

                    onDismissed: root.entryDismissed(modelData.id)
                    onCloseRequested: root.closeRequested()
                }
            }
        }
    }
}
