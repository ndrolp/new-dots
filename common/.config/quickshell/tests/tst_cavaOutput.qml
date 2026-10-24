import QtQuick
import QtTest
import "../services/CavaOutput.js" as CavaOutput

// How the Cava bar element reads cava: the config the shell runs it with and
// each line it prints turned into bar heights, and what happens when it fails.
TestCase {
    name: "CavaOutput"

    function test_aFrameBecomesOneHeightPerBarFromZeroToOne() {
        compare(CavaOutput.frameHeights("0;500;1000;250;", 4), [0, 0.5, 1, 0.25]);
    }

    function test_silenceIsFlatBars() {
        compare(CavaOutput.frameHeights("0;0;0;", 3), [0, 0, 0]);
        compare(CavaOutput.flatHeights(3), [0, 0, 0]);
    }

    function test_aFrameIsSilentOnlyWhenEveryBarIsFlat() {
        verify(CavaOutput.frameSilent([0, 0, 0]));
        verify(CavaOutput.frameSilent([]));
        verify(!CavaOutput.frameSilent([0, 0.01, 0]));
    }

    function test_heightsOutsideTheRangeAreClamped() {
        compare(CavaOutput.frameHeights("1200;-5;", 2), [1, 0]);
    }

    function test_aShortOrGarbledFrameFillsTheMissingBarsFlat() {
        compare(CavaOutput.frameHeights("1000;", 3), [1, 0, 0]);
        compare(CavaOutput.frameHeights("abc;500", 2), [0, 0.5]);
        compare(CavaOutput.frameHeights("", 2), [0, 0]);
    }

    function test_extraBarsInAFrameAreIgnored() {
        compare(CavaOutput.frameHeights("1000;1000;1000;", 2), [1, 1]);
    }

    function test_cavaComputesTheMostBarsAnyDrawnCavaAsksFor() {
        compare(CavaOutput.sharedBarCount([8, 20, 12]), 20);
        compare(CavaOutput.sharedBarCount([6]), 6);
    }

    function test_withNoCavaDrawnTheBarCountIsTheDefault() {
        compare(CavaOutput.sharedBarCount([]), 12);
    }

    function test_resamplingToFewerBarsKeepsEachGroupsTallestBar() {
        compare(CavaOutput.resample([0, 0.5, 1, 0.25], 2), [0.5, 1]);
        compare(CavaOutput.resample([0.2, 0.4, 0.6, 0.8, 1, 0], 3), [0.4, 0.8, 1]);
    }

    function test_resamplingToTheSameCountChangesNothing() {
        compare(CavaOutput.resample([0.1, 0.2, 0.3], 3), [0.1, 0.2, 0.3]);
    }

    function test_resamplingAnUnevenSplitCoversEveryBar() {
        // 5 bars into 2: bars 0-1 and 2-4.
        compare(CavaOutput.resample([1, 0, 0, 0, 0.5], 2), [1, 0.5]);
    }

    function test_resamplingNothingGivesFlatBars() {
        compare(CavaOutput.resample([], 3), [0, 0, 0]);
    }

    // The config is cava's ini format; read back the settings that matter.
    function setting(config, section, key) {
        let current = "";
        for (const line of config.split("\n")) {
            const header = line.match(/^\[(.+)\]$/);
            if (header)
                current = header[1];
            const entry = line.match(/^(\w+) = (.*)$/);
            if (entry && current === section && entry[1] === key)
                return entry[2];
        }
        return undefined;
    }

    function test_theConfigListensToTheDefaultOutputAndPrintsFramesAsText() {
        const config = CavaOutput.config(12);

        compare(setting(config, "general", "bars"), "12");
        compare(setting(config, "input", "method"), "pipewire");
        compare(setting(config, "input", "source"), "auto");
        compare(setting(config, "output", "method"), "raw");
        compare(setting(config, "output", "raw_target"), "/dev/stdout");
        compare(setting(config, "output", "data_format"), "ascii");
        compare(setting(config, "output", "ascii_max_range"), "1000");
        compare(setting(config, "output", "bar_delimiter"), "59");
        compare(setting(config, "output", "frame_delimiter"), "10");
    }

    function test_theConfigDrawsOneSetOfFrequencyBarsNotTwoMirroredChannels() {
        compare(setting(CavaOutput.config(12), "output", "channels"), "mono");
    }

    function test_cavaIsStartedAgainAfterAFewSecondsThenLessOftenTheMoreItFails() {
        compare(CavaOutput.retryDelay(1), 3000);
        compare(CavaOutput.retryDelay(2), 6000);
        compare(CavaOutput.retryDelay(3), 12000);
        compare(CavaOutput.retryDelay(20), 60000);
    }

    // The shell runs cava through sh, which exits 127 when cava isn't found.
    function test_aFailedCavaExplainsWhetherItIsMissingFailedToStartOrStopped() {
        compare(CavaOutput.failureHint(127, false, 3000), "cava isn't installed, so the bars stay flat.");
        compare(CavaOutput.failureHint(1, false, 3000),
            "cava failed to start, so the bars stay flat. Trying again in 3 seconds.");
        compare(CavaOutput.failureHint(-1, false, 60000),
            "cava failed to start, so the bars stay flat. Trying again in 60 seconds.");
        compare(CavaOutput.failureHint(1, true, 3000),
            "cava stopped unexpectedly, so the bars stay flat. Trying again in 3 seconds.");
    }

    // What the one shared cava does as bars start and stop drawing Cava, as
    // the default output or bar count changes and as cava exits.
    function test_cavaRunsOnlyWhileSomeBarDrawsCava() {
        const drawn = CavaOutput.drawnChanged(CavaOutput.stopped, true);
        verify(drawn.running);

        const notDrawn = CavaOutput.drawnChanged(drawn, false);
        verify(!notDrawn.running);
        verify(!CavaOutput.stopped.running);
    }

    // A new default output or bar count: cava stops and starts again once it
    // exited, without counting that exit as a failure.
    function test_cavaRestartsWhenTheDefaultOutputOrBarCountChanges() {
        const running = CavaOutput.drawnChanged(CavaOutput.stopped, true);

        const stopping = CavaOutput.restartAsked(running);
        verify(!stopping.running);

        const restarted = CavaOutput.exited(stopping, 0);
        verify(restarted.running);
        verify(!restarted.retrying);
        compare(restarted.failureHint, "");
        compare(restarted.failures, 0);
    }

    function test_cavaIsTriedAgainAWhileAfterAnExitNobodyAskedFor() {
        const failed = CavaOutput.exited(CavaOutput.drawnChanged(CavaOutput.stopped, true), 1);
        verify(!failed.running);
        verify(failed.retrying);
        compare(failed.retryDelay, 3000);
        compare(failed.failureHint, "cava failed to start, so the bars stay flat. Trying again in 3 seconds.");

        const retried = CavaOutput.retryDue(failed);
        verify(retried.running);
        verify(!retried.retrying);

        const failedAgain = CavaOutput.exited(retried, 1);
        compare(failedAgain.retryDelay, 6000);
        compare(failedAgain.failureHint, "cava failed to start, so the bars stay flat. Trying again in 6 seconds.");
    }

    function test_aCavaThatPrintedFramesAndExitedStoppedUnexpectedly() {
        const printing = CavaOutput.framePrinted(CavaOutput.drawnChanged(CavaOutput.stopped, true));
        compare(printing.failureHint, "");

        const crashed = CavaOutput.exited(printing, 139);
        verify(crashed.retrying);
        compare(crashed.retryDelay, 3000);
        compare(crashed.failureHint, "cava stopped unexpectedly, so the bars stay flat. Trying again in 3 seconds.");
    }

    function test_aFrameClearsTheHintAndTheFailures() {
        const failed = CavaOutput.exited(CavaOutput.drawnChanged(CavaOutput.stopped, true), 1);
        const printing = CavaOutput.framePrinted(CavaOutput.retryDue(failed));

        compare(printing.failureHint, "");
        compare(printing.failures, 0);
    }

    function test_cavaStopsBeingTriedAgainOnceNoBarDrawsIt() {
        const failed = CavaOutput.exited(CavaOutput.drawnChanged(CavaOutput.stopped, true), 1);

        const notDrawn = CavaOutput.drawnChanged(failed, false);
        verify(!notDrawn.running);
        verify(!notDrawn.retrying);
        compare(notDrawn.failureHint, "");
        verify(!CavaOutput.retryDue(notDrawn).running);
        verify(!CavaOutput.exited(CavaOutput.drawnChanged(failed, false), 1).retrying);
    }

    function test_aRestartWhileCavaIsntRunningStartsNothing() {
        compare(CavaOutput.restartAsked(CavaOutput.stopped), CavaOutput.stopped);
    }
}
