import QtQuick
import "../../config" as Config
import "PrinterLabels.js" as Labels
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
    // { adding, failedKey, failure }: the printer being added (its key; the
    // others wait for it), and the one whose add failed and why.
    property var addState: ({ adding: "", failedKey: "", failure: "" })

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
            readonly property bool failed: root.addState.failedKey === modelData.key
                && root.addState.failure !== ""

            width: root.width
            spacing: 2

            Panels.DeviceRow {
                width: parent.width
                appearance: root.appearance
                title: printer.modelData.model
                subtitle: Labels.connectionText(printer.modelData.connection)
                    + (printer.modelData.driverless ? "" : " · Can't print driverless")
                trailingWidth: action.width + 6

                Item {
                    id: action

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    height: 30

                    Panels.PopupButton {
                        anchors.fill: parent
                        visible: printer.modelData.driverless && root.addState.adding !== printer.modelData.key
                        appearance: root.appearance
                        interactive: root.addState.adding === ""
                        label: "Add"
                        labelColor: theme.accent
                        onActivated: root.addRequested(printer.modelData)
                    }

                    Panels.ShellText {
                        anchors.centerIn: parent
                        visible: root.addState.adding === printer.modelData.key
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
                    text: root.addState.failure
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
