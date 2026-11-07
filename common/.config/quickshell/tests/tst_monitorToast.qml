import QtQuick
import QtTest
import "../services/MonitorToast.js" as MonitorToast

// When the toasts about monitors come up. Pure: services/MonitorSetups.qml carries it out.
TestCase {
    name: "MonitorToast"

    function test_anUnknownCombinationIsOffered() {
        const state = MonitorToast.afterReading(MonitorToast.idle, "AOC\nSamsung", false, false);
        compare(state.offering, true);
    }

    function test_aKnownCombinationShowsNothing() {
        const state = MonitorToast.afterReading(MonitorToast.idle, "AOC\nSamsung", true, false);
        compare(state.offering, false);
    }

    function test_aDismissedToastDoesNotComeBackOnTheNextReading() {
        const offered = MonitorToast.afterReading(MonitorToast.idle, "AOC", false, false);
        const again = MonitorToast.afterReading(MonitorToast.dismissed(offered), "AOC", false, false);
        compare(again.offering, false);
    }

    function test_anOfferStaysThroughAnotherReadingOfTheSameCombination() {
        const offered = MonitorToast.afterReading(MonitorToast.idle, "AOC", false, false);
        compare(MonitorToast.afterReading(offered, "AOC", false, false).offering, true);
    }

    function test_theOfferGoesOnceTheCombinationIsSaved() {
        const offered = MonitorToast.afterReading(MonitorToast.idle, "AOC", false, false);
        compare(MonitorToast.afterReading(offered, "AOC", true, false).offering, false);
    }

    function test_replacingAnIgnoredMonitorOffersAgain() {
        let state = MonitorToast.afterReading(MonitorToast.idle, "AOC", false, false);
        state = MonitorToast.dismissed(state);
        state = MonitorToast.afterReading(state, "Samsung", true, false);
        compare(MonitorToast.afterReading(state, "AOC", false, false).offering, true);
    }

    function test_aMonitorPluggedInWhileLockedWaitsForUnlock() {
        const before = MonitorToast.afterReading(MonitorToast.idle, "Samsung", true, false);
        const locked = MonitorToast.afterReading(before, "AOC\nSamsung", false, true);
        compare(locked.offering, false);
        compare(MonitorToast.afterReading(locked, "AOC\nSamsung", false, false).offering, true);
    }

    function test_aMonitorGoneAgainBeforeUnlockNeverShows() {
        const before = MonitorToast.afterReading(MonitorToast.idle, "Samsung", true, false);
        const locked = MonitorToast.afterReading(before, "AOC\nSamsung", false, true);
        compare(MonitorToast.afterReading(locked, "Samsung", true, false).offering, false);
    }

    function test_aShellReloadDoesNotOfferTheSameCombinationAgain() {
        const restored = MonitorToast.restored("AOC");
        compare(MonitorToast.afterReading(restored, "AOC", false, false).offering, false);
    }

    function test_noMonitorsIsNothingToOffer() {
        compare(MonitorToast.afterReading(MonitorToast.idle, "", false, false).offering, false);
    }

    function test_aFailureIsANoticeUntilDismissed() {
        const told = MonitorToast.withNotice(MonitorToast.idle, "It failed.");
        compare(told.notice, "It failed.");
        compare(MonitorToast.noticeDismissed(told).notice, "");
    }

    function test_aSecondFailureAddsToTheNotice() {
        const first = MonitorToast.withNotice(MonitorToast.idle, "It failed.");
        compare(MonitorToast.withNotice(first, "So did this.").notice, "It failed. So did this.");
        compare(MonitorToast.withNotice(first, "It failed.").notice, "It failed.");
    }

    function test_aNoticeStaysThroughReadingsAndTheOfferBesideIt() {
        const told = MonitorToast.withNotice(MonitorToast.idle, "It failed.");
        const read = MonitorToast.afterReading(told, "AOC", false, false);
        compare(read.notice, "It failed.");
        compare(read.offering, true);
        compare(MonitorToast.dismissed(read).notice, "It failed.");
        compare(MonitorToast.noticeDismissed(read).offering, true);
    }

    function test_anUnreadableFileIsToldOnce() {
        const notice = MonitorToast.noticed("unreadable\n", "");
        verify(notice.message.indexOf("automatic") !== -1);
        compare(MonitorToast.noticed("readable\n", notice.told).message, "");
    }

    function test_aFallbackNamesTheMonitorOnce() {
        const notice = MonitorToast.noticed("readable\nAOC Q27G42XE\n", "");
        verify(notice.message.indexOf("AOC Q27G42XE") !== -1);
        compare(MonitorToast.noticed("readable\nAOC Q27G42XE\n", notice.told).message, "");
    }

    function test_onlyAMonitorNewlyFallenBackIsNamed() {
        const first = MonitorToast.noticed("readable\nAOC\n", "");
        const second = MonitorToast.noticed("readable\nAOC\nPhilips\n", first.told);
        verify(second.message.indexOf("Philips") !== -1);
        verify(second.message.indexOf("AOC") === -1);
    }

    function test_aFallbackThatEndedIsToldAgainNextTime() {
        const first = MonitorToast.noticed("readable\nAOC\n", "");
        const ended = MonitorToast.noticed("readable\n", first.told);
        compare(ended.told, "");
        verify(MonitorToast.noticed("readable\nAOC\n", ended.told).message.indexOf("AOC") !== -1);
    }
}
