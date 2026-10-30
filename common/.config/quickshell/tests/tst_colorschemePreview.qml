import QtQuick
import QtTest
import "../components/panels/ColorschemePreview.js" as ColorschemePreview

// Which colorscheme preview the colorscheme selector runs: one at a time, and
// a preview asked for while another runs waits for it, the latest one winning.
TestCase {
    name: "ColorschemePreview"

    function test_previewingWhileIdleRunsThePreview() {
        const step = ColorschemePreview.requested(ColorschemePreview.idle, "nord");

        compare(step.start, "nord");
    }

    function test_previewingWhileAPreviewRunsWaitsForItThenRunsTheLatest() {
        let step = ColorschemePreview.requested(ColorschemePreview.idle, "nord");
        step = ColorschemePreview.requested(step.state, "tokyonight");
        compare(step.start, "");
        step = ColorschemePreview.requested(step.state, "catppuccin");
        compare(step.start, "");

        step = ColorschemePreview.exited(step.state);

        compare(step.start, "catppuccin");
        compare(ColorschemePreview.exited(step.state).start, "");
    }

    // Closing the selector mid-preview previews the active colorscheme again.
    function test_leavingThePreviewWhileOneRunsRunsTheActiveColorschemeAfterIt() {
        let step = ColorschemePreview.shown(ColorschemePreview.idle, "everforestdark");
        step = ColorschemePreview.requested(step.state, "nord");
        step = ColorschemePreview.requested(step.state, "everforestdark");

        compare(ColorschemePreview.exited(step.state).start, "everforestdark");
    }

    function test_goingBackToTheRunningPreviewQueuesNothing() {
        let step = ColorschemePreview.requested(ColorschemePreview.idle, "nord");
        step = ColorschemePreview.requested(step.state, "tokyonight");
        step = ColorschemePreview.requested(step.state, "nord");

        compare(ColorschemePreview.exited(step.state).start, "");
    }

    function test_previewingWhatIsAlreadyShownRunsNothing() {
        const shown = ColorschemePreview.shown(ColorschemePreview.idle, "nord");

        compare(ColorschemePreview.requested(shown.state, "nord").start, "");
        compare(ColorschemePreview.requested(shown.state, "").start, "");
    }
}
