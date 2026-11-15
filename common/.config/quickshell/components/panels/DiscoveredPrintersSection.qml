import QtQuick
import "../../config" as Config
import "../../services/Printers.js" as Printers
import "." as Panels

// The Discovered printers heading of the Printers panel: the printers found
// on the network and USB that aren't added yet, each labelled with how it's
// connected and with *Add*. One that can't print driverless, or whose add
// failed, says so and offers *Print settings* (system-config-printer). It
// only shows what it's handed and asks; the discovered printers service
// looks and adds.
Column {
    id: root

    required property var appearance
    // [{ key, model, service, connection, uri, driverless }]
    property var discovered: []
    // Why printers can't be found ("" otherwise).
    property string problem: ""
    // The printer being added (its key); the others wait for it.
    property string adding: ""
    // The printer whose add failed (its key), and why.
    property string addFailureKey: ""
    property string addFailure: ""

    signal addRequested(var printer)
    signal printSettingsRequested()

    spacing: 4

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Discovered printers"
    }

    Panels.ShellText {
        width: parent.width
        visible: root.problem !== ""
        leftPadding: 8
        text: root.problem
        wrapMode: Text.Wrap
        color: theme.orange
        font.pixelSize: root.appearance.textSize - 1
    }

    Panels.ShellText {
        visible: root.discovered.length === 0 && root.problem === ""
        leftPadding: 8
        text: "Looking for printers…"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    Repeater {
        model: root.discovered

        delegate: Column {
            id: printer

            required property var modelData
            readonly property bool failed: root.addFailureKey === modelData.key && root.addFailure !== ""

            width: root.width
            spacing: 2

            Panels.PopupRow {
                width: parent.width
                height: 44
                appearance: root.appearance

                Panels.ShellText {
                    id: glyph

                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰐪"
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize + 6
                }

                Column {
                    anchors.left: glyph.right
                    anchors.leftMargin: 10
                    anchors.right: action.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Panels.ShellText {
                        width: parent.width
                        text: printer.modelData.model
                        elide: Text.ElideRight
                        color: theme.text
                        font.pixelSize: root.appearance.textSize - 1
                    }

                    Panels.ShellText {
                        width: parent.width
                        text: Printers.connectionText(printer.modelData.connection)
                            + (printer.modelData.driverless ? "" : " · Can't print driverless")
                        elide: Text.ElideRight
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 3
                    }
                }

                Item {
                    id: action

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    height: 30

                    Panels.PopupButton {
                        anchors.fill: parent
                        visible: printer.modelData.driverless && root.adding !== printer.modelData.key
                        appearance: root.appearance
                        interactive: root.adding === ""
                        label: "Add"
                        labelColor: theme.accent
                        onActivated: root.addRequested(printer.modelData)
                    }

                    Panels.ShellText {
                        anchors.centerIn: parent
                        visible: root.adding === printer.modelData.key
                        text: "Adding…"
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize - 1
                    }

                    Panels.PopupButton {
                        anchors.fill: parent
                        visible: !printer.modelData.driverless
                        appearance: root.appearance
                        label: "Print settings"
                        onActivated: root.printSettingsRequested()
                    }
                }
            }

            // A failed add: why, and the way to add it with a driver.
            Column {
                width: parent.width
                visible: printer.failed
                leftPadding: 40
                spacing: 6
                bottomPadding: 6

                Panels.ShellText {
                    width: parent.width - parent.leftPadding
                    text: root.addFailure
                    wrapMode: Text.Wrap
                    color: theme.red
                    font.pixelSize: root.appearance.textSize - 2
                }

                Panels.PopupButton {
                    width: 120
                    visible: printer.modelData.driverless
                    appearance: root.appearance
                    label: "Print settings"
                    onActivated: root.printSettingsRequested()
                }
            }
        }
    }
}
