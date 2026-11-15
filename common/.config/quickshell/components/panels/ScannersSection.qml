import QtQuick
import "../../config" as Config
import "../../services/Printers.js" as Printers
import "." as Panels

// The Scanners heading of the Printers panel: every scanner SANE can see,
// network or USB, each with *Scan…*, which asks for the scan view. When
// sane-airscan is missing it says so, since no network scanner can show up.
Column {
    id: root

    required property var appearance
    // [{ device, name, connection }]
    property var scanners: []
    // Why network scanners can't be found ("" otherwise).
    property string problem: ""

    signal scanRequested(var scanner)

    spacing: 4

    Config.Theme {
        id: theme
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Scanners"
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
        visible: root.scanners.length === 0
        leftPadding: 8
        text: "No scanners found"
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 1
    }

    Repeater {
        model: root.scanners

        delegate: Panels.PopupRow {
            id: scanner

            required property var modelData

            width: root.width
            height: 44
            appearance: root.appearance
            interactive: false

            Panels.ShellText {
                id: glyph

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "󰚫"
                color: theme.textMuted
                font.pixelSize: root.appearance.textSize + 6
            }

            Column {
                anchors.left: glyph.right
                anchors.leftMargin: 10
                anchors.right: scanButton.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Panels.ShellText {
                    width: parent.width
                    text: scanner.modelData.name
                    elide: Text.ElideRight
                    color: theme.text
                    font.pixelSize: root.appearance.textSize - 1
                }

                Panels.ShellText {
                    width: parent.width
                    text: Printers.connectionText(scanner.modelData.connection)
                    elide: Text.ElideRight
                    color: theme.textMuted
                    font.pixelSize: root.appearance.textSize - 3
                }
            }

            Panels.PopupButton {
                id: scanButton

                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 80
                appearance: root.appearance
                label: "Scan…"
                onActivated: root.scanRequested(scanner.modelData)
            }
        }
    }
}
