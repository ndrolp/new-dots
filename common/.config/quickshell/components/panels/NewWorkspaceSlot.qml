import QtQuick
import "../../config" as Config

// The empty slot after a monitor's last workspace. A window dropped here goes to
// a new workspace numbered `workspace`, following the same rules as any other
// drop. It isn't a workspace, so a click on it passes through as one outside any
// workspace.
WorkspaceDropSurface {
    id: root

    restBorderColor: theme.border
    restBorderWidth: 1

    Config.Theme {
        id: theme
    }

    ShellText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: "+  " + root.workspace
        color: root.highlighted ? theme.accent : theme.textDisabled
        font.pixelSize: root.appearance.textSize
        font.bold: true
    }

    ShellText {
        anchors.centerIn: parent
        text: "New workspace"
        color: theme.textDisabled
        font.pixelSize: root.appearance.textSize - 3
    }
}
