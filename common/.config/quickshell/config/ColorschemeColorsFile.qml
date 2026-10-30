import Quickshell.Io
import QtQuick
import "ColorschemeColors.js" as ColorschemeColors

// Keeps the active colorscheme's colours as read from colors.json. Swapping
// that link isn't noticed by watching the file, so the changer asks for the
// colours again over IPC: `quickshell ipc call colorscheme reload`.
// Created once, through ColorschemeColors.shared().
QtObject {
    id: root

    readonly property var colours: ColorschemeColors.fromJson(file.text())

    property var file: FileView {
        id: file

        path: Qt.resolvedUrl("colors.json")
        // Read at startup before anything is drawn, so the shell never shows the fallback first.
        blockLoading: true
    }

    property var ipc: IpcHandler {
        target: "colorscheme"

        function reload(): void {
            file.reload();
        }
    }
}
