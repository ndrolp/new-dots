import QtQuick
import QtTest
import "../modules/FailedReload.js" as FailedReload

// The failed reload notice: what a failed live reload shows (a critical
// notification naming the first error line, saying the previous config is
// still running), that a repeat failure replaces it instead of stacking, and
// that the next successful reload withdraws it. modules/FailedReload.qml
// carries the commands out.
TestCase {
    name: "FailedReload"

    readonly property string error: "\n  file:///home/me/.config/quickshell/shell.qml:12:5: Type CapsuleFeature unavailable\n"
        + "file:///home/me/.config/quickshell/modules/CapsuleFeature.qml:3:1: module \"Foo\" is not installed\n"

    function test_aFailedReloadRaisesACriticalNotificationWithTheFirstErrorLine() {
        compare(FailedReload.failedCommand(error, 0), [
            "notify-send", "-a", "Quickshell", "-u", "critical", "-i", "dialog-error", "-p",
            "Shell reload failed",
            "Quickshell couldn't load its config and is still running the previous one.\n"
                + "file:///home/me/.config/quickshell/shell.qml:12:5: Type CapsuleFeature unavailable"
        ]);
    }

    function test_aRepeatFailureReplacesTheNoticeAlreadyShown() {
        const command = FailedReload.failedCommand(error, 42);

        compare(command.slice(0, 10), [
            "notify-send", "-a", "Quickshell", "-u", "critical", "-i", "dialog-error", "-p", "-r", "42"
        ]);
    }

    function test_theErrorIsShownAsTextNotMarkup() {
        const body = FailedReload.failedCommand("Expected token `<` & got `>`", 0).slice(-1)[0];

        compare(body.split("\n")[1], "Expected token `&lt;` &amp; got `&gt;`");
    }

    function test_aFailureWithNoErrorTextStillSaysSo() {
        const body = FailedReload.failedCommand(" \n", 0).slice(-1)[0];

        compare(body, "Quickshell couldn't load its config and is still running the previous one.\n"
            + "No error details.");
    }

    function test_theShownNoticeIsTheIdNotifySendPrints() {
        compare(FailedReload.shownId("17\n"), 17);
        compare(FailedReload.shownId(""), 0);
        compare(FailedReload.shownId("not an id"), 0);
    }

    function test_aSuccessfulReloadWithdrawsTheShownNotice() {
        compare(FailedReload.completedCommand(17), [
            "gdbus", "call", "--session",
            "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications",
            "--method", "org.freedesktop.Notifications.CloseNotification", "17"
        ]);
    }

    function test_aSuccessfulReloadWithNoNoticeShownDoesNothing() {
        compare(FailedReload.completedCommand(0), null);
    }
}
