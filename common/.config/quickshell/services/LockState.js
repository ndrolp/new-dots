.pragma library

// When the lock screen locks, checks a password and unlocks: plain state,
// changed only through the functions below, which return the next state.
// Lock.qml locks the session while `locked` and hands the password to PAM
// while `phase` is "checking". Pure, no Quickshell.
// - locked: the session is locked.
// - phase: "waiting" for a password, "checking" one, or "unlocked".
// - error: what the lock screen says under the password field ("" for
//   nothing).
const unlocked = { locked: false, phase: "unlocked", error: "" };

// Something asked to lock (the `lock` IPC call). Asking again while locked
// changes nothing, so hypridle can ask as often as it likes.
function lockAsked(state) {
    if (state.locked)
        return state;
    return { locked: true, phase: "waiting", error: "" };
}

// The password field on the focused monitor was submitted with `password`:
// PAM checks it, unless it's empty or one is being checked already.
function passwordSubmitted(state, password) {
    if (state.phase !== "waiting" || !password)
        return state;
    return Object.assign({}, state, { phase: "checking", error: "" });
}

// What the lock screen says when PAM didn't let the password through.
const errors = {
    failed: "Wrong password",
    maxTries: "Too many tries, wait a moment"
};

// PAM finished checking the password with `result`: one of PamResult's
// "success", "failed", "error" and "maxTries", or "startFailed" when PAM
// couldn't even start (a PamError). Only "success" unlocks; anything else
// waits for the password again and says why.
function authFinished(state, result) {
    if (state.phase !== "checking")
        return state;
    if (result === "success")
        return unlocked;
    return Object.assign({}, state, {
        phase: "waiting",
        error: errors[result] || "Couldn't check the password"
    });
}
