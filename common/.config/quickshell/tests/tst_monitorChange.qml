import QtQuick
import QtTest
import "../services/MonitorChange.js" as MonitorChange
import "../services/MonitorSetup.js" as MonitorSetup

// The 15-second Keep or Revert on every change, shared by Displays and the quick switch.
TestCase {
    name: "MonitorChange"

    function setup(position) {
        return [{ description: "AOC", port: "DP-2", mode: "2560x1440@143.91", position: position,
            scale: 1, transform: 0, disabled: false, mirror: "" }];
    }

    readonly property string savedText: '{\n  "setups": [\n    { "monitors": [{ "description": "Other" }] }\n  ]\n}\n'

    function started(fileText) {
        return MonitorChange.changed(MonitorChange.idle, fileText, setup("0x0"), setup("100x0"), 1000);
    }

    function setupsIn(text) {
        return MonitorSetup.parsedFile(text).setups;
    }

    function test_rememberingSavesTheSetupWithoutAskingHyprland() {
        const step = MonitorChange.remembered(savedText, setup("0x0"));
        compare(step.apply, false);
        compare(MonitorChange.counting(step.state), false);
        compare(setupsIn(step.text).length, 2);
        compare(setupsIn(step.text)[1].monitors[0].position, "0x0");
    }

    function test_rememberingLeavesASavedCombinationAlone() {
        compare(MonitorChange.remembered(MonitorChange.kept(started(null).state).text, setup("0x0")), null);
    }

    function test_nothingIsRememberedInAFileThatCantBeRead() {
        compare(MonitorChange.remembered("{ not json", setup("0x0")), null);
    }

    function test_aChangeWritesTheFileAndAsksHyprlandToApplyIt() {
        const step = started(savedText);
        compare(setupsIn(step.text).length, 2);
        compare(setupsIn(step.text)[1].monitors[0].position, "100x0");
        compare(step.apply, true);
    }

    function test_theCountdownIsFifteenSeconds() {
        const step = started(savedText);
        compare(MonitorChange.counting(step.state), true);
        compare(MonitorChange.secondsLeft(step.state, 1000), 15);
        compare(MonitorChange.secondsLeft(step.state, 8500), 8);
    }

    function test_unansweredItExpiresAtZero() {
        const state = started(savedText).state;
        compare(MonitorChange.expired(state, 15999), false);
        compare(MonitorChange.expired(state, 16000), true);
    }

    function test_anotherChangeRestartsTheCountdownAndStillGoesBackToTheStart() {
        const first = started(savedText);
        const second = MonitorChange.changed(first.state, first.text, setup("100x0"), setup("200x0"), 5000);
        compare(MonitorChange.secondsLeft(second.state, 5000), 15);
        const back = MonitorChange.reverted(second.state);
        compare(setupsIn(back.text)[1].monitors[0].position, "0x0");
    }

    function test_keepSavesTheSetupAndForgetsWhatCameBefore() {
        const step = started(savedText);
        const kept = MonitorChange.kept(step.state);
        compare(MonitorChange.counting(kept.state), false);
        compare(MonitorSetup.parsedFile(kept.text).unkept, undefined);
        compare(setupsIn(kept.text)[1].monitors[0].position, "100x0");
        compare(kept.apply, false);
    }

    function test_revertPutsTheArrangementBackFirst() {
        const step = started(savedText);
        const back = MonitorChange.reverted(step.state);
        compare(setupsIn(back.text)[1].monitors[0].position, "0x0");
        compare(back.apply, true);
        compare(MonitorChange.counting(back.state), false);
        compare(MonitorChange.restoring(back.state), true);
    }

    // Revert saves nothing: a setup that wasn't saved before isn't saved after.
    function test_afterRevertTheFileIsExactlyWhatItWas() {
        const step = started(savedText);
        const back = MonitorChange.reverted(step.state);
        const done = MonitorChange.restored(back.state, false);
        compare(done.text, savedText);
        compare(done.remove, false);
        compare(done.apply, false);
        compare(MonitorChange.restoring(done.state), false);
    }

    // Revert leaves no trace: not even an empty file.
    function test_afterRevertAFileThatWasntThereIsGone() {
        const step = started(null);
        const back = MonitorChange.reverted(step.state);
        const done = MonitorChange.restored(back.state);
        compare(done.remove, true);
    }

    // The shell can stop in the middle of a countdown; only Keep saves.
    function test_aCountdownCutShortIsFoundInTheFile() {
        const step = started(savedText);
        const state = MonitorChange.interrupted(step.text);
        const back = MonitorChange.reverted(state);
        compare(setupsIn(back.text)[1].monitors[0].position, "0x0");
        compare(MonitorChange.restored(back.state).text, savedText);
    }

    function test_aFileWithNoCountdownInItNeedsNothing() {
        compare(MonitorChange.interrupted(savedText), null);
        compare(MonitorChange.interrupted(null), null);
        compare(MonitorChange.interrupted("{ not json"), null);
    }

    // A failed read is neither a file nor no file: nothing may be built on it.
    function test_aFileThatCouldntBeLoadedIsNotAMissingFile() {
        compare(MonitorSetup.loadedText("missing", ""), null);
        compare(MonitorSetup.loadedText("loaded", savedText), savedText);
        compare(MonitorSetup.loadedText("failed", ""), undefined);
        compare(MonitorSetup.loadedText("failed", savedText), undefined);
    }

    function test_anEmptyFileIsNotAMissingFile() {
        compare(MonitorSetup.parsedFile(MonitorSetup.loadedText("loaded", "")), null);
    }

    function test_nothingIsBuiltOnAFailedRead() {
        const unread = MonitorSetup.loadedText("failed", "");
        compare(MonitorSetup.parsedFile(unread), null);
        compare(MonitorChange.remembered(unread, setup("0x0")), null);
        compare(MonitorChange.forgotten(unread, "Other"), null);
        compare(MonitorChange.interrupted(unread), null);
    }

    function test_aChangeNeedsSomethingNewThatShowsSomething() {
        const here = setup("0x0");
        compare(MonitorChange.canTry(setup("100x0"), here, false), true);
        compare(MonitorChange.canTry(setup("100x0"), here, true), false);
        compare(MonitorChange.canTry(setup("0x0"), here, false), false);
        compare(MonitorChange.canTry([], here, false), false);
        const dark = setup("0x0");
        dark[0].disabled = true;
        compare(MonitorChange.canTry(dark, here, false), false);
    }

    function test_rememberingNeedsWhatTheMonitorsAlreadyAre() {
        const here = setup("0x0");
        compare(MonitorChange.canRemember(setup("0x0"), here, false, false), true);
        compare(MonitorChange.canRemember(setup("100x0"), here, false, false), false);
        compare(MonitorChange.canRemember(setup("0x0"), here, true, false), false);
        compare(MonitorChange.canRemember(setup("0x0"), here, false, true), false);
        compare(MonitorChange.canRemember([], [], false, false), false);
    }

    function test_hyprlandTakingATrialLeavesItCounting() {
        const answer = MonitorChange.afterAnswer(started(savedText).state, "ok\n");
        compare(answer.warning, "");
        compare(answer.step, null);
    }

    function test_hyprlandTakingARevertPutsTheFileBack() {
        const back = MonitorChange.reverted(started(savedText).state);
        const answer = MonitorChange.afterAnswer(back.state, "ok");
        compare(answer.warning, "");
        compare(answer.step.text, savedText);
        compare(answer.step.apply, false);
    }

    // A rule that failed can leave some monitors changed, so the restored file is applied too.
    function test_aFailedTrialPutsTheFileBackAndAppliesIt() {
        const answer = MonitorChange.afterAnswer(started(savedText).state, "no such rule");
        verify(answer.warning.indexOf("no such rule") !== -1);
        compare(answer.step.text, savedText);
        compare(answer.step.apply, true);
        compare(MonitorChange.counting(answer.step.state), false);
    }

    function test_aFailedRevertPutsTheFileBackAndAppliesIt() {
        const back = MonitorChange.reverted(started(savedText).state);
        const answer = MonitorChange.afterAnswer(back.state, "");
        compare(answer.step.text, savedText);
        compare(answer.step.apply, true);
    }

    function test_aFailedTrialWithNoFileBeforeRemovesItAndApplies() {
        const answer = MonitorChange.afterAnswer(started(null).state, "no");
        compare(answer.step.remove, true);
        compare(answer.step.apply, true);
    }

    // That second apply failing has nowhere left to go.
    function test_failingAgainOnlyWarns() {
        const answer = MonitorChange.afterAnswer(MonitorChange.idle, "no");
        verify(answer.warning !== "");
        compare(answer.step, null);
    }

    // Hyprland went back by itself: its deadline passed, or the config was reloaded.
    function test_aCountdownIsOvertakenOnceTheFileHasNoUnkept() {
        const step = started(savedText);
        compare(MonitorChange.overtaken(step.state, step.text), false);
        compare(MonitorChange.overtaken(step.state, savedText), true);
        compare(MonitorChange.overtaken(step.state, null), true);
    }

    function test_onlyACountdownCanBeOvertaken() {
        compare(MonitorChange.overtaken(MonitorChange.idle, savedText), false);
        const back = MonitorChange.reverted(started(savedText).state);
        compare(MonitorChange.overtaken(back.state, savedText), false);
    }

    function test_aFileThatCantBeReadOvertakesNothing() {
        const state = started(savedText).state;
        compare(MonitorChange.overtaken(state, undefined), false);
        compare(MonitorChange.overtaken(state, "{ not json"), false);
    }

    function test_forgettingWritesTheFileWithoutAskingHyprland() {
        const text = '{ "setups": [{ "monitors": [{ "description": "Other" }] }, { "monitors": [{ "description": "AOC" }] }] }';
        const step = MonitorChange.forgotten(text, "Other");
        compare(setupsIn(step.text).length, 1);
        compare(setupsIn(step.text)[0].monitors[0].description, "AOC");
        compare(step.apply, false);
        compare(step.remove, false);
        compare(MonitorChange.counting(step.state), false);
    }

    function test_forgettingTheLastSetupLeavesAFileHyprlandCanRead() {
        compare(MonitorChange.forgotten(savedText, "Other").text, '{\n  "setups": []\n}\n');
    }

    function test_nothingIsForgottenFromAFileThatCantBeRead() {
        compare(MonitorChange.forgotten("{ not json", "Other"), null);
    }

    function test_nothingIsDueWhileIdle() {
        compare(MonitorChange.expired(MonitorChange.idle, 99999), false);
        compare(MonitorChange.secondsLeft(MonitorChange.idle, 0), 0);
    }
}
