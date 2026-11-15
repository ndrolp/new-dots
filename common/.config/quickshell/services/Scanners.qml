import Quickshell
import Quickshell.Io
import QtQuick
import "Scanners.js" as Scanners

// The scanners SANE can see, for the Printers panel, and scanning one page
// from one of them. It lists them only while `watching` (the panel is
// open), every few seconds so the list keeps up, and nothing runs while
// the panel is closed. When a scanner's scan view opens, the colour modes
// it offers are read. A scan, run by scan.sh, finishes even if the panel
// closes. scanimage's output is read in Scanners.js. The last scan
// settings are kept in appearance.json.
QtObject {
    id: root

    required property var appearance

    property bool watching: false
    // [{ device, name, connection }], in the order SANE lists them.
    property var scanners: []
    // Why network scanners can't be found ("" when nothing's wrong).
    property string problem: ""

    // The settings the scan view shows and the next scan uses
    // ({ resolution, mode, format }).
    readonly property var settings: Scanners.settings(appearance.scanSettings)
    // The colour modes the scanner `modesScanner` offers
    // ([{ label, value, sane }]); all three until they're read.
    property string modesScanner: ""
    property var modes: Scanners.availableModes([])
    readonly property bool scanning: scanProcess.running
    // 0 to 1 while scanning.
    property real progress: 0
    // Why the last scan failed, or what scanimage said when it saved one
    // all the same ("" otherwise), and where the last one went.
    property string scanFailure: ""
    property string lastScan: ""

    function refresh() {
        if (!listProcess.running)
            listProcess.running = true;
    }

    // Reads which colour modes the scanner `device` offers, when its scan
    // view opens.
    function readModes(device) {
        modesScanner = device;
        modes = Scanners.availableModes([]);
        if (!modesProcess.running)
            startModes();
    }

    function startModes() {
        modesProcess.scanner = modesScanner;
        modesProcess.command = Scanners.modesCommand(modesScanner);
        modesProcess.running = true;
    }

    // Keeps `key` of the scan settings as `value` for every scan after.
    function setSetting(key, value) {
        const next = Scanners.settings(settings);
        next[key] = value;
        appearance.scanSettings = Scanners.settings(next);
    }

    function scan(device) {
        if (scanProcess.running)
            return;
        const path = Scanners.filePath(Quickshell.env("HOME"), new Date(), settings.format);
        scanFailure = "";
        lastScan = "";
        progress = 0;
        scanProcess.path = path;
        scanProcess.command = Scanners.scanCommand(Quickshell.shellDir + "/services/scan.sh", device, settings,
            path, device === modesScanner ? modes : []);
        scanProcess.running = true;
    }

    onWatchingChanged: {
        if (watching) {
            refresh();
            if (!airscanCheck.running)
                airscanCheck.running = true;
        }
    }

    property var poll: Timer {
        interval: 5000
        repeat: true
        running: root.watching
        onTriggered: root.refresh()
    }

    property var listProcess: Process {
        id: listProcess

        command: Scanners.listCommand
        stdout: StdioCollector {
            // Only a change replaces the list, so the panel's rows aren't
            // rebuilt on every poll.
            onStreamFinished: {
                const scanners = Scanners.parse(text);
                if (JSON.stringify(scanners) !== JSON.stringify(root.scanners))
                    root.scanners = scanners;
            }
        }
    }

    property var airscanCheck: Process {
        id: airscanCheck

        command: Scanners.airscanCheckCommand
        onExited: exitCode => root.problem = exitCode === 0 ? "" : Scanners.airscanMissing
    }

    property var scanProcess: Process {
        id: scanProcess

        property string path: ""
        property string errors: ""

        onStarted: errors = ""
        // scanimage rewrites its progress with carriage returns, not lines.
        stderr: SplitParser {
            splitMarker: "\r"
            onRead: data => {
                scanProcess.errors = (scanProcess.errors + data + "\r").slice(-4000);
                root.progress = Scanners.progressOf(scanProcess.errors);
            }
        }
        // A scan is saved when its file is there, even if scanimage failed
        // after; what it said is shown all the same.
        onExited: exitCode => {
            const outcome = Scanners.outcomeOf(exitCode, errors);
            root.scanFailure = outcome.problem;
            if (outcome.saved) {
                root.progress = 1;
                root.lastScan = path;
                Quickshell.execDetached(Scanners.savedNoticeCommand(path));
            }
        }
    }

    property var modesProcess: Process {
        id: modesProcess

        // The scanner these modes are of; a reply for another is dropped.
        property string scanner: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (modesProcess.scanner === root.modesScanner)
                    root.modes = Scanners.availableModes(Scanners.parseModes(text));
            }
        }
        // Another scanner's view was opened while this one was read.
        onExited: {
            if (scanner !== root.modesScanner)
                root.startModes();
        }
    }
}
