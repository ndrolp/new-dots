import Quickshell.Io
import QtQuick
import "." as Panels

// Runs the session actions; what they look like is SessionActions, which
// tests can load without Quickshell.Io.
Column {
    id: root

    required property var appearance

    width: parent ? parent.width : 0
    spacing: 14

    Process {
        id: sessionAction
    }

    Panels.SettingsHeading {
        appearance: root.appearance
        text: "Idle"
        topPadding: 4
    }

    Panels.SettingsHint {
        width: parent.width
        appearance: root.appearance
        text: "Hypridle locks after 10 minutes, turns displays off after 10.5 minutes, and suspends after 30 minutes."
    }

    Panels.SessionActions {
        appearance: root.appearance
        onRequested: command => {
            sessionAction.command = command;
            sessionAction.running = true;
        }
    }
}
