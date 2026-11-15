import QtQuick
import "../../config" as Config
import "../../services/Scanners.js" as Scanners
import "." as Panels

// The scan view of the Printers panel, for one scanner: resolution, colour
// mode and format (the last ones used), *Scan*, then its progress, and
// what went wrong if it failed. There is no preview pass. It only shows
// what it's handed and asks; the scanners service scans and keeps the
// settings.
Column {
    id: root

    required property var appearance
    // { device, name, connection }
    property var scanner: null
    // { resolution, mode, format }
    property var settings: Scanners.settings(undefined)
    property bool scanning: false
    // 0 to 1 while scanning.
    property real progress: 0
    property string failure: ""
    // Where the last scan went, shown once it's done.
    property string lastScan: ""

    signal settingChosen(string key, var value)
    signal scanRequested()
    signal backRequested()

    spacing: 10

    Config.Theme {
        id: theme
    }

    Row {
        width: parent.width
        spacing: 8

        Panels.PopupButton {
            width: 70
            appearance: root.appearance
            label: "‹ Back"
            interactive: !root.scanning
            onActivated: root.backRequested()
        }

        Panels.ShellText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 78
            text: root.scanner ? root.scanner.name : ""
            elide: Text.ElideRight
            color: theme.text
            font.pixelSize: root.appearance.textSize
        }
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Resolution"
    }

    Panels.SettingsChoice {
        width: parent.width
        appearance: root.appearance
        options: Scanners.resolutions
        value: root.settings.resolution
        enabled: !root.scanning
        onChosen: value => root.settingChosen("resolution", value)
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Colour"
    }

    Panels.SettingsChoice {
        width: parent.width
        appearance: root.appearance
        options: Scanners.modes
        value: root.settings.mode
        enabled: !root.scanning
        onChosen: value => root.settingChosen("mode", value)
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Format"
    }

    Panels.SettingsChoice {
        width: parent.width
        appearance: root.appearance
        options: Scanners.formats
        value: root.settings.format
        enabled: !root.scanning
        onChosen: value => root.settingChosen("format", value)
    }

    Panels.PopupButton {
        width: parent.width
        appearance: root.appearance
        interactive: !root.scanning && root.scanner !== null
        label: root.scanning ? "Scanning…" : "Scan"
        labelColor: theme.accent
        onActivated: root.scanRequested()
    }

    Panels.PopupProgress {
        width: parent.width
        visible: root.scanning
        appearance: root.appearance
        fraction: root.progress
    }

    Panels.ShellText {
        width: parent.width
        visible: !root.scanning && root.failure !== ""
        text: root.failure
        wrapMode: Text.Wrap
        color: theme.red
        font.pixelSize: root.appearance.textSize - 1
    }

    Panels.ShellText {
        width: parent.width
        visible: !root.scanning && root.failure === "" && root.lastScan !== ""
        text: "Saved to " + root.lastScan
        elide: Text.ElideMiddle
        color: theme.textMuted
        font.pixelSize: root.appearance.textSize - 2
    }
}
