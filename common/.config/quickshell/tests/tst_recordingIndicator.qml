import QtQuick
import QtTest
import "../components/bar/RecordingIndicator.js" as RecordingIndicator

// The recording indicator: shown while something records, with the time
// since the recording started.
TestCase {
    name: "RecordingIndicator"

    function test_underAMinuteShowsMinutesAndSeconds() {
        compare(RecordingIndicator.elapsedText(0), "0:00");
        compare(RecordingIndicator.elapsedText(7), "0:07");
        compare(RecordingIndicator.elapsedText(59), "0:59");
    }

    function test_minutesKeepTwoDigitSeconds() {
        compare(RecordingIndicator.elapsedText(60), "1:00");
        compare(RecordingIndicator.elapsedText(754), "12:34");
    }

    function test_anHourOrMoreAddsHours() {
        compare(RecordingIndicator.elapsedText(3600), "1:00:00");
        compare(RecordingIndicator.elapsedText(3723), "1:02:03");
    }

    function test_partSecondsAreDroppedAndNegativeTimeIsZero() {
        compare(RecordingIndicator.elapsedText(7.9), "0:07");
        compare(RecordingIndicator.elapsedText(-3), "0:00");
    }

    function test_nothingRecordingHidesTheIndicator() {
        const recordings = RecordingIndicator.recordings(0);

        compare(recordings, []);
        verify(!RecordingIndicator.shown(recordings));
        verify(!RecordingIndicator.stoppable(recordings));
    }

    function test_theShellsOwnRecordingShowsItAndCanBeStopped() {
        const recordings = RecordingIndicator.recordings(5000);

        compare(recordings, [{ kind: "own", startedAt: 5000 }]);
        verify(RecordingIndicator.shown(recordings));
        verify(RecordingIndicator.stoppable(recordings));
    }

    function test_theElapsedTimeCountsFromWhenTheRecordingStarted() {
        const recordings = RecordingIndicator.recordings(10000);

        compare(RecordingIndicator.elapsedSince(recordings, 10000), "0:00");
        compare(RecordingIndicator.elapsedSince(recordings, 10000 + 83500), "1:23");
        compare(RecordingIndicator.elapsedSince([], 10000), "");
    }
}
