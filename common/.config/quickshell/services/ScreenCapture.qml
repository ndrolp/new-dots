import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool grimAvailable: false
    property bool slurpAvailable: false
    property bool wfRecorderAvailable: false
    property bool wayshotAvailable: false
    property string picturesDirectory: ""
    readonly property string outputDirectory: picturesDirectory === ""
        ? "" : picturesDirectory + "/Screenshots"
    property bool busy: false
    property bool recording: recordingProcess.running
    property string recordingPath: ""
    property string pendingAction: ""
    property string pendingOutput: ""
    property string pendingMonitor: ""
    property string pendingGeometry: ""
    property string lastOutputPath: ""
    property string status: ""

    signal captureCompleted(string path)
    signal captureFailed(string message)

    Component.onCompleted: {
        toolCheck.running = true;
        picturesDirectoryQuery.running = true;
    }

    function timestamp() {
        const now = new Date();
        const twoDigits = value => String(value).padStart(2, "0");

        return now.getFullYear() + "-" + twoDigits(now.getMonth() + 1) + "-"
            + twoDigits(now.getDate()) + "-" + twoDigits(now.getHours())
            + twoDigits(now.getMinutes()) + twoDigits(now.getSeconds());
    }

    function queue(action, monitor) {
        if (busy || recording) {
            status = recording ? "Recording is already in progress." : "Capture is already in progress.";
            return;
        }

        if (outputDirectory === "") {
            status = "Pictures directory is not available.";
            captureFailed(status);
            return;
        }

        pendingAction = action;
        pendingMonitor = monitor || "";
        pendingGeometry = "";
        pendingOutput = outputDirectory + "/"
            + (action.startsWith("record") ? "recording-" : "screenshot-")
            + timestamp() + (action.startsWith("record") ? ".mp4" : ".png");
        busy = true;
        status = "Preparing capture…";
        outputDirectoryCreate.command = ["mkdir", "-p", outputDirectory];
        outputDirectoryCreate.running = true;
    }

    function screenshotOutput(monitor) {
        if (!grimAvailable && !wayshotAvailable) {
            status = "Neither grim nor wayshot is installed.";
            captureFailed(status);
            return;
        }

        queue("screenshot-output", monitor);
    }

    function screenshotRegion() {
        if (!grimAvailable || !slurpAvailable) {
            status = "Region screenshots require grim and slurp.";
            captureFailed(status);
            return;
        }

        queue("screenshot-region", "");
    }

    function recordOutput(monitor) {
        if (!wfRecorderAvailable) {
            status = "Recording requires wf-recorder.";
            captureFailed(status);
            return;
        }

        queue("record-output", monitor);
    }

    function recordRegion() {
        if (!wfRecorderAvailable || !slurpAvailable) {
            status = "Region recording requires wf-recorder and slurp.";
            captureFailed(status);
            return;
        }

        queue("record-region", "");
    }

    function stopRecording() {
        if (!recordingProcess.running)
            return;

        status = "Saving recording…";
        recordingProcess.signal(2);
    }

    function startPendingAction() {
        if (pendingAction.endsWith("region")) {
            status = "Select a region…";
            regionSelection.running = true;
            return;
        }

        runCapture("");
    }

    function runCapture(geometry) {
        if (pendingAction === "screenshot-output") {
            screenshotProcess.command = grimAvailable
                ? ["grim", "-o", pendingMonitor, pendingOutput]
                : ["wayshot", "-f", pendingOutput];
            screenshotProcess.running = true;
        } else if (pendingAction === "screenshot-region") {
            screenshotProcess.command = ["grim", "-g", geometry, pendingOutput];
            screenshotProcess.running = true;
        } else if (pendingAction === "record-output") {
            recordingPath = pendingOutput;
            recordingProcess.command = ["wf-recorder", "-o", pendingMonitor, "-f", pendingOutput];
            recordingProcess.running = true;
            busy = false;
            pendingAction = "";
            status = "Recording…";
        } else if (pendingAction === "record-region") {
            recordingPath = pendingOutput;
            recordingProcess.command = ["wf-recorder", "-g", geometry, "-f", pendingOutput];
            recordingProcess.running = true;
            busy = false;
            pendingAction = "";
            status = "Recording…";
        }
    }

    function finishScreenshot(exitCode) {
        const output = pendingOutput;
        pendingAction = "";
        busy = false;

        if (exitCode === 0) {
            lastOutputPath = output;
            status = "Screenshot saved.";
            notification.exec(["notify-send", "-a", "Quickshell", "Screenshot",
                "Saved to " + output]);
            captureCompleted(output);
        } else {
            status = "Screenshot failed.";
            captureFailed(status);
        }
    }

    property var toolCheck: Process {
        id: toolCheck

        command: ["sh", "-c",
            "for tool in grim slurp wf-recorder wayshot; do "
            + "command -v \"$tool\" >/dev/null && printf '%s\\n' \"$tool\"; done"]

        stdout: SplitParser {
            onRead: data => {
                const tool = data.trim();

                if (tool === "grim")
                    root.grimAvailable = true;
                else if (tool === "slurp")
                    root.slurpAvailable = true;
                else if (tool === "wf-recorder")
                    root.wfRecorderAvailable = true;
                else if (tool === "wayshot")
                    root.wayshotAvailable = true;
            }
        }
    }

    property var picturesDirectoryQuery: Process {
        id: picturesDirectoryQuery

        command: ["xdg-user-dir", "PICTURES"]

        stdout: SplitParser {
            onRead: data => root.picturesDirectory = data.trim()
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || root.picturesDirectory === "")
                root.status = "Unable to resolve the Pictures directory.";
        }
    }

    property var outputDirectoryCreate: Process {
        id: outputDirectoryCreate

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.startPendingAction();
            } else {
                root.busy = false;
                root.pendingAction = "";
                root.status = "Unable to create the Screenshots directory.";
                root.captureFailed(root.status);
            }
        }
    }

    property var regionSelection: Process {
        id: regionSelection

        command: ["slurp"]

        stdout: SplitParser {
            onRead: data => root.pendingGeometry = data.trim()
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.pendingGeometry !== "") {
                root.runCapture(root.pendingGeometry);
            } else {
                root.busy = false;
                root.pendingAction = "";
                root.status = "Region selection cancelled.";
            }
        }
    }

    property var screenshotProcess: Process {
        id: screenshotProcess

        onExited: (exitCode, exitStatus) => root.finishScreenshot(exitCode)
    }

    property var recordingProcess: Process {
        id: recordingProcess

        onExited: (exitCode, exitStatus) => {
            const output = root.recordingPath;
            root.recordingPath = "";

            if (exitCode === 0) {
                root.lastOutputPath = output;
                root.status = "Recording saved.";
                notification.exec(["notify-send", "-a", "Quickshell", "Recording",
                    "Saved to " + output]);
                root.captureCompleted(output);
            } else {
                root.status = "Recording failed.";
                root.captureFailed(root.status);
            }
        }
    }

    property var notification: Process {
        id: notification
    }
}
