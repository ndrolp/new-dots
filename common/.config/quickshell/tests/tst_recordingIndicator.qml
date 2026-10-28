import QtQuick
import QtTest
import "../components/bar/RecordingIndicator.js" as RecordingIndicator

// The recording indicator: shown while something records, with the time
// since the recording started.
TestCase {
    name: "RecordingIndicator"

    // How the time reads (m:ss, h:mm:ss) is StatusText.duration's, tested
    // there.
    function test_aLongRecordingShowsHours() {
        const recordings = RecordingIndicator.recordings(10000);

        compare(RecordingIndicator.elapsedSince(recordings, 10000 + 3723000), "1:02:03");
    }

    function test_nothingRecordingHidesTheIndicator() {
        const recordings = RecordingIndicator.recordings(0);

        compare(recordings, []);
        verify(!RecordingIndicator.shown(recordings));
        verify(!RecordingIndicator.stoppable(recordings));
    }

    function test_theShellsOwnRecordingShowsItAndCanBeStopped() {
        const recordings = RecordingIndicator.recordings(5000);

        compare(recordings, [{ kind: RecordingIndicator.kinds.own, startedAt: 5000 }]);
        verify(RecordingIndicator.shown(recordings));
        verify(RecordingIndicator.stoppable(recordings));
    }

    function test_theElapsedTimeCountsFromWhenTheRecordingStarted() {
        const recordings = RecordingIndicator.recordings(10000);

        compare(RecordingIndicator.elapsedSince(recordings, 10000), "0:00");
        compare(RecordingIndicator.elapsedSince(recordings, 10000 + 83500), "1:23");
        compare(RecordingIndicator.elapsedSince([], 10000), "");
    }

    // PipeWire nodes and links as plain objects, shaped like the ones the bar
    // reads from Quickshell's Pipewire service. The portal's screen is a
    // Video/Source with no device behind it; the camera is a v4l2 device.
    readonly property var portalScreen: ({
        id: 101,
        isStream: false,
        properties: { "media.class": "Video/Source", "node.name": "xdph-streaming-0",
            "application.name": "xdg-desktop-portal-hyprland" }
    })
    readonly property var camera: ({
        id: 84,
        isStream: false,
        properties: { "media.class": "Video/Source", "media.role": "Camera",
            "device.api": "v4l2", "node.name": "v4l2_input.pci-0000_00_14.0-usb-0_4_1.0" }
    })
    readonly property var firefoxStream: ({
        id: 120,
        isStream: true,
        properties: { "media.class": "Stream/Input/Video", "application.name": "Firefox",
            "application.process.binary": "firefox" }
    })
    readonly property var obsStream: ({
        id: 130,
        isStream: true,
        properties: { "media.class": "Stream/Input/Video", "application.process.binary": "obs" }
    })

    function test_anAppReadingThePortalsScreenIsSharingIt() {
        const shares = RecordingIndicator.screenShares([portalScreen, firefoxStream],
            [{ source: 101, target: 120 }]);

        compare(shares, [{ id: 101, app: "Firefox" }]);
    }

    function test_aCameraIsNotScreenSharing() {
        const shares = RecordingIndicator.screenShares([camera, firefoxStream],
            [{ source: 84, target: 120 }]);

        compare(shares, []);
    }

    function test_anAppWithoutANameIsNamedAfterItsBinary() {
        const shares = RecordingIndicator.screenShares([portalScreen, obsStream],
            [{ source: 101, target: 130 }]);

        compare(shares, [{ id: 101, app: "obs" }]);
    }

    function test_aShareKeepsWhenItWasFirstSeen() {
        const first = RecordingIndicator.startTimes([], [{ id: 101, app: "" }], 5000);
        const later = RecordingIndicator.startTimes(first, [{ id: 101, app: "Firefox" },
            { id: 102, app: "obs" }], 9000);

        compare(later, [{ id: 101, app: "Firefox", startedAt: 5000 },
            { id: 102, app: "obs", startedAt: 9000 }]);
        compare(RecordingIndicator.startTimes(later, [], 12000), []);
    }

    function test_anotherAppSharingShowsTheIndicatorButCannotBeStopped() {
        const recordings = RecordingIndicator.recordings(0,
            [{ id: 101, app: "Firefox", startedAt: 5000 }]);

        compare(recordings, [{ kind: RecordingIndicator.kinds.share, app: "Firefox", startedAt: 5000 }]);
        verify(RecordingIndicator.shown(recordings));
        verify(!RecordingIndicator.stoppable(recordings));
    }

    function test_theShellsOwnRecordingCanBeStoppedWhileAnotherAppShares() {
        const recordings = RecordingIndicator.recordings(8000,
            [{ id: 101, app: "Firefox", startedAt: 5000 }]);

        verify(RecordingIndicator.stoppable(recordings));
        compare(RecordingIndicator.elapsedSince(recordings, 65000), "1:00");
    }

    function test_clickingWhileOthersShareNamesEachAppOnce() {
        const recordings = RecordingIndicator.recordings(0, [
            { id: 101, app: "Firefox", startedAt: 5000 },
            { id: 102, app: "Firefox", startedAt: 6000 },
            { id: 103, app: "", startedAt: 7000 },
            { id: 104, app: "obs", startedAt: 8000 }
        ]);

        compare(RecordingIndicator.sharingText(recordings), "Firefox, obs");
        compare(RecordingIndicator.sharingText(RecordingIndicator.recordings(0,
            [{ id: 103, app: "", startedAt: 7000 }])), "An app");
    }

    // Virtual cameras are Video/Sources with no device behind them too, but
    // they aren't a screen being shared.
    readonly property var obsVirtualCamera: ({
        id: 140,
        isStream: false,
        properties: { "media.class": "Video/Source",
            "node.name": "v4l2_input.platform-v4l2loopback-000",
            "node.description": "OBS Virtual Camera" }
    })
    readonly property var loopbackNode: ({
        id: 141,
        isStream: false,
        properties: { "media.class": "Video/Source", "node.name": "dummy-video-0",
            "node.description": "Dummy video device (0x0000)",
            "api.v4l2.cap.driver": "v4l2 loopback" }
    })
    readonly property var namedWebcam: ({
        id: 142,
        isStream: false,
        properties: { "media.class": "Video/Source", "node.name": "virtual-cam-7",
            "node.nick": "Webcam", "node.description": "Virtual Camera" }
    })

    function test_virtualCamerasAreNotScreenSharing() {
        for (const node of [obsVirtualCamera, loopbackNode, namedWebcam]) {
            const shares = RecordingIndicator.screenShares([node, firefoxStream],
                [{ source: node.id, target: 120 }]);

            compare(shares, [], node.properties["node.name"]);
        }
    }

    function test_aVirtualCameraNextToASharedScreenLeavesOnlyTheScreen() {
        const shares = RecordingIndicator.screenShares(
            [obsVirtualCamera, portalScreen, firefoxStream],
            [{ source: 140, target: 120 }, { source: 101, target: 120 }]);

        compare(shares, [{ id: 101, app: "Firefox" }]);
    }

    function test_theRecordingKindsAreFixed() {
        const kinds = RecordingIndicator.kinds;

        verify(Object.isFrozen(kinds));
        verify(kinds.own !== kinds.share);
        compare(Object.keys(kinds).sort(), ["own", "share"]);
    }
}
