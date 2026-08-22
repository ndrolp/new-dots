import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property int durationSeconds: 25 * 60
    property int remainingSeconds: durationSeconds
    property bool running: false
    property bool started: false

    readonly property string remainingLabel: {
        const minutes = Math.floor(remainingSeconds / 60);
        const seconds = remainingSeconds % 60;
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function selectMinutes(minutes) {
        durationSeconds = minutes * 60;
        remainingSeconds = durationSeconds;
        running = false;
        started = false;
    }

    function adjustMinutes(minutes) {
        durationSeconds = Math.max(10 * 60, durationSeconds + (minutes * 60));
        remainingSeconds = Math.max(0, remainingSeconds + (minutes * 60));
    }

    function start() {
        if (remainingSeconds <= 0)
            remainingSeconds = durationSeconds;

        started = true;
        running = true;
    }

    function stop() {
        running = false;
    }

    function cancel() {
        running = false;
        started = false;
        remainingSeconds = durationSeconds;
    }

    function complete() {
        running = false;
        remainingSeconds = 0;
        started = false;
        completionSound.exec(["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"]);
        completionNotification.exec([
            "notify-send", "-a", "Pomodoro", "-u", "normal",
            "Pomodoro complete", "Your focus timer has finished."
        ]);
    }

    property var tickTimer: Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remainingSeconds <= 1)
                root.complete();
            else
                root.remainingSeconds--;
        }
    }

    property var completionSound: Process {
        id: completionSound
    }

    property var completionNotification: Process {
        id: completionNotification
    }
}
