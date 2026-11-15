import QtQuick
import "../../config" as Config
import "../../services/Printers.js" as Printers
import "." as Panels

// The Printers heading of the Printers panel: every printer with its state,
// connection and whether it's the default. Pressing a printer opens it,
// with *Set default* and *Remove* (which asks once more). It only shows
// what it's handed and asks for changes; the printers service makes them.
Column {
    id: root

    required property var appearance
    // [{ name, description, state, reason, connection, isDefault }]
    property var printers: []
    // Why the printers couldn't be read or changed ("" otherwise).
    property string failure: ""
    // While a change runs; the buttons wait for it.
    property bool busy: false
    // The open printer's name, and the one whose removal waits for a yes.
    property string expanded: ""
    property string removeArmed: ""

    signal setDefaultRequested(string name)
    signal removeRequested(string name)

    spacing: 4

    onExpandedChanged: removeArmed = ""

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Printers"
    }

    Panels.ShellText {
        width: parent.width
        visible: root.failure !== ""
        text: root.failure
        wrapMode: Text.Wrap
        color: theme.red
        font.pixelSize: root.appearance.textSize - 1
    }

    Panels.ShellText {
        visible: root.printers.length === 0 && root.failure === ""
        leftPadding: 8
        text: "No printers added"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    Repeater {
        model: root.printers

        delegate: Column {
            id: printer

            required property var modelData
            readonly property bool open: root.expanded === modelData.name
            readonly property bool armed: root.removeArmed === modelData.name

            width: root.width
            spacing: 2

            Panels.PopupRow {
                width: parent.width
                height: 44
                appearance: root.appearance
                color: printer.open ? theme.backgroundSecondary
                    : hovered ? theme.surfaceHover : "transparent"

                Panels.ShellText {
                    id: glyph

                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰐪"
                    color: printer.modelData.state === "error" ? theme.red
                        : printer.modelData.state === "stopped" ? theme.orange : theme.textMuted
                    font.pixelSize: root.appearance.textSize + 6
                }

                Column {
                    anchors.left: glyph.right
                    anchors.leftMargin: 10
                    anchors.right: defaultBadge.visible ? defaultBadge.left : parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Panels.ShellText {
                        width: parent.width
                        text: printer.modelData.name
                        elide: Text.ElideRight
                        color: theme.text
                        font.pixelSize: root.appearance.textSize - 1
                    }

                    Panels.ShellText {
                        width: parent.width
                        text: Printers.statusText(printer.modelData) + " · "
                            + Printers.connectionText(printer.modelData.connection)
                        elide: Text.ElideRight
                        color: printer.modelData.state === "error" ? theme.red : theme.textMuted
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                Rectangle {
                    id: defaultBadge

                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    visible: printer.modelData.isDefault
                    width: defaultLabel.implicitWidth + 14
                    height: defaultLabel.implicitHeight + 6
                    radius: height / 2
                    color: "transparent"
                    border.color: theme.accent
                    border.width: 1

                    Panels.ShellText {
                        id: defaultLabel

                        anchors.centerIn: parent
                        text: "Default"
                        color: theme.accent
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                TapHandler {
                    onTapped: root.expanded = printer.open ? "" : printer.modelData.name
                }
            }

            // An open printer. Its print jobs and *Test page* go here too.
            Column {
                width: parent.width
                visible: printer.open
                leftPadding: 40
                spacing: 6
                bottomPadding: 6

                Panels.ShellText {
                    visible: printer.modelData.description !== ""
                    width: parent.width - parent.leftPadding
                    text: printer.modelData.description
                    elide: Text.ElideRight
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 2
                }

                Panels.ShellText {
                    visible: printer.armed
                    text: "Remove " + printer.modelData.name + "?"
                    color: theme.red
                    font.pixelSize: root.appearance.textSize - 1
                }

                Row {
                    spacing: 6

                    Panels.PopupButton {
                        width: 100
                        visible: !printer.armed && !printer.modelData.isDefault
                        appearance: root.appearance
                        interactive: !root.busy
                        label: "Set default"
                        onActivated: root.setDefaultRequested(printer.modelData.name)
                    }

                    Panels.PopupButton {
                        width: 80
                        visible: !printer.armed
                        appearance: root.appearance
                        interactive: !root.busy
                        label: "Remove"
                        labelColor: theme.red
                        onActivated: root.removeArmed = printer.modelData.name
                    }

                    Panels.PopupButton {
                        width: 100
                        visible: printer.armed
                        appearance: root.appearance
                        interactive: !root.busy
                        label: "Yes, remove"
                        labelColor: theme.red
                        onActivated: {
                            root.removeArmed = "";
                            root.removeRequested(printer.modelData.name);
                        }
                    }

                    Panels.PopupButton {
                        width: 80
                        visible: printer.armed
                        appearance: root.appearance
                        label: "Cancel"
                        onActivated: root.removeArmed = ""
                    }
                }
            }
        }
    }
}
