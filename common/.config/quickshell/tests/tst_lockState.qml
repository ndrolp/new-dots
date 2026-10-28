import QtQuick
import QtTest
import "../components/lock/LockState.js" as LockState

// When the lock screen locks, checks a password and unlocks. Lock.qml carries
// the decisions out with WlSessionLock and PamContext, which don't load here.
TestCase {
    name: "LockState"

    function test_askingToLockLocks() {
        const state = LockState.lockAsked(LockState.unlocked);
        verify(state.locked);
        compare(state.phase, "waiting");
    }

    function test_askingToLockWhileLockedChangesNothing() {
        const state = checking();
        compare(LockState.lockAsked(state), state);
    }

    function checking() {
        return LockState.passwordSubmitted(LockState.lockAsked(LockState.unlocked), "secret");
    }

    // The lock screen fades away before the session unlocks under it.
    function test_theRightPasswordStartsUnlocking() {
        const state = LockState.authFinished(checking(), "success");
        verify(state.locked);
        compare(state.phase, "unlocking");
        compare(state.error, "");
    }

    function test_onceTheLockScreenHasFadedTheSessionUnlocks() {
        const state = LockState.unlockFinished(LockState.authFinished(checking(), "success"));
        verify(!state.locked);
        compare(state.phase, "unlocked");
    }

    function test_fadingAwayFinishesOnlyWhileUnlocking() {
        const waiting = LockState.lockAsked(LockState.unlocked);
        compare(LockState.unlockFinished(waiting), waiting);
        compare(LockState.unlockFinished(checking()), checking());
        compare(LockState.unlockFinished(LockState.unlocked), LockState.unlocked);
    }

    // hypridle asking to lock while the lock screen fades away keeps it.
    function test_askingToLockWhileUnlockingStaysLocked() {
        const state = LockState.lockAsked(LockState.authFinished(checking(), "success"));
        verify(state.locked);
        compare(state.phase, "waiting");
        compare(LockState.unlockFinished(state), state);
    }

    function test_aWrongPasswordStaysLockedAndSaysSo() {
        const state = LockState.authFinished(checking(), "failed");
        verify(state.locked);
        compare(state.phase, "waiting");
        compare(state.error, "Wrong password");
    }

    function test_tooManyWrongPasswordsSaysToWait() {
        const state = LockState.authFinished(checking(), "maxTries");
        verify(state.locked);
        compare(state.phase, "waiting");
        compare(state.error, "Too many tries, wait a moment");
    }

    function test_whenPamCantCheckThePasswordItStaysLockedAndSaysSo() {
        for (const result of ["error", "startFailed"]) {
            const state = LockState.authFinished(checking(), result);
            verify(state.locked);
            compare(state.phase, "waiting");
            compare(state.error, "Couldn't check the password");
        }
    }

    function test_tryingAgainClearsTheError() {
        const failed = LockState.authFinished(checking(), "failed");
        compare(LockState.passwordSubmitted(failed, "other").error, "");
    }

    function test_anEmptyPasswordIsNotChecked() {
        const waiting = LockState.lockAsked(LockState.unlocked);
        compare(LockState.passwordSubmitted(waiting, ""), waiting);
    }

    function test_submittingWhileAPasswordIsCheckedChangesNothing() {
        const state = checking();
        compare(LockState.passwordSubmitted(state, "again"), state);
    }

    function test_submittingWhileUnlockedChangesNothing() {
        compare(LockState.passwordSubmitted(LockState.unlocked, "secret"), LockState.unlocked);
    }

    function test_aResultNobodyWaitsForChangesNothing() {
        const waiting = LockState.lockAsked(LockState.unlocked);
        compare(LockState.authFinished(waiting, "success"), waiting);
        compare(LockState.authFinished(LockState.unlocked, "failed"), LockState.unlocked);
    }

    function test_unlockingThenLockingAgainLocks() {
        const unlocking = LockState.authFinished(checking(), "success");
        const state = LockState.lockAsked(LockState.unlockFinished(unlocking));
        verify(state.locked);
        compare(state.error, "");
    }

    function test_afterAReloadWhileLockedItStaysLockedAndAsksForThePassword() {
        const state = LockState.restored(true);
        verify(state.locked);
        compare(state.phase, "waiting");
        compare(state.error, "");
    }

    function test_afterAReloadWhileUnlockedItStaysUnlocked() {
        compare(LockState.restored(false), LockState.unlocked);
    }

    function test_afterAReloadWithNothingSavedItStaysUnlocked() {
        compare(LockState.restored(undefined), LockState.unlocked);
    }
}
