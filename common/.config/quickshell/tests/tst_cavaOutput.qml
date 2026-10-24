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

    function test_theConfigDrawsOneSpectrumNotTwoMirroredChannels() {
        compare(setting(CavaOutput.config(12), "output", "channels"), "mono");
    }

    function test_cavaIsStartedAgainAfterAFewSecondsThenLessOftenTheMoreItFails() {
        compare(CavaOutput.retryDelay(1), 3000);
        compare(CavaOutput.retryDelay(2), 6000);
        compare(CavaOutput.retryDelay(3), 12000);
        compare(CavaOutput.retryDelay(20), 60000);
    }

    // The shell runs cava through sh, which exits 127 when cava isn't found.
    function test_aFailedCavaExplainsWhetherItIsMissingOrFailedToStart() {
        compare(CavaOutput.failureHint(127), "cava isn't installed, so the bars stay flat.");
        compare(CavaOutput.failureHint(1), "cava failed to start, so the bars stay flat. Trying again in a few seconds.");
        compare(CavaOutput.failureHint(-1), "cava failed to start, so the bars stay flat. Trying again in a few seconds.");
    }
}
