import Quickshell
import Quickshell.Io
import QtQuick
import "FailedReload.js" as FailedReload

// The failed reload notice: when a live reload fails, the shell that keeps
// running (the previous config) raises a critical notification with the first
// error line; the next successful reload withdraws it. The notice's id is a
// persistent property, so the config a successful reload brings in knows what
// to withdraw. The decisions are in FailedReload.js.
Scope {
    id: root

    PersistentProperties {
        id: notice

        reloadableId: "failedReloadNotice"

        // The notification shown for the last failed reload; 0 for none.
        property int shownId: 0
    }

    Connections {
        target: Quickshell

        function onReloadFailed(errorString) {
            raise.command = FailedReload.failedCommand(errorString, notice.shownId);
            raise.running = true;
        }

        function onReloadCompleted() {
            const command = FailedReload.completedCommand(notice.shownId);
            notice.shownId = 0;
            if (command !== null)
                withdraw.exec(command);
        }
    }

    Process {
        id: raise

        stdout: StdioCollector {
            onStreamFinished: notice.shownId = FailedReload.parseShownId(text)
        }
    }

    Process {
        id: withdraw
    }
}
