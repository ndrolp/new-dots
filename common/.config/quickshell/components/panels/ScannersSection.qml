import QtQuick
import "../../config" as Config
import "PrinterLabels.js" as Labels
import "." as Panels

// The Scanners heading of the Printers panel: every scanner SANE can see,
// network or USB, each with *Scan…*, which asks for the scan view. When
// sane-airscan is missing it says so, since no network scanner can show up.
Column {
    id: root

    required property var appearance
    // [{ saneName, name, connection }]
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

        delegate: Panels.PrinterRow {
            id: scanner

            required property var modelData

            width: root.width
            appearance: root.appearance
            interactive: false
            glyph: "󰚫"
            title: modelData.name
            subtitle: Labels.connectionText(modelData.connection)
            trailingWidth: scanButton.width + 8

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
