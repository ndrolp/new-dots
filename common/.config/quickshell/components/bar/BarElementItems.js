.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "../panels/ControlCenterNames.js" as Names
.import "LiveElements.js" as LiveElements

// Which of BarElementItems' elements are shown: pure, no Quickshell.

// Whether `element` is shown: it must be enabled in `barElements`, or be one
// of a capsule's `live` elements (LiveElements.liveElements), which its
// row lists switched off. A live element of a collapsed capsule shows only
// while it is active (LiveElements.active). Otherwise, the ones that can have
// nothing to show are hidden then: media without a player, the battery
// without one, the recording and privacy indicators while they aren't
// active and cava while silent, and the pomodoro while none is started
// (running or paused); every other element is always shown when enabled.
// `status` says what there is: `live`, `expanded` (whether the capsule is),
// `player`, `recordings`, `keepAwakeOn`, `captures` (see
// LiveElements.activeRules), `hasBattery`, `cavaSilent` and
// `pomodoroStarted`.
function itemVisible(element, barElements, status) {
    const live = (status.live || []).indexOf(element) !== -1;
    if (!BarProfileModel.elementEnabled(barElements, element) && !live)
        return false;
    if (live && status.expanded !== true)
        return LiveElements.active(element, status);
    if (element === "media")
        return !!status.player;
    if (element === "battery")
        return status.hasBattery;
    if (element === "recording" || element === "privacy")
        return LiveElements.active(element, status);
    if (element === "cava")
        return !status.cavaSilent;
    if (element === "pomodoro")
        return status.pomodoroStarted === true;
    return true;
}

// The bar element a popup opens under, for popups not named after theirs.
// The control center is the bell's popup, whose saved id stays
// "notifications".
var popupElements = Object.freeze({
    "system": "systemMonitor",
    "pomodoro": "clock",
    [Names.controlCenter.popup]: "notifications"
});

function popupElement(popup) {
    return popupElements[popup] || popup;
}

// The bar elements with no popup of their own.
var elementsWithoutPopup = Object.freeze(["arch", "workspaces", "currentApp", "recording", "cava"]);

function opensPopup(element) {
    return !elementsWithoutPopup.includes(element);
}

// Scrolling over the media element: a step (components/WheelSteps.js) forward skips
// the player it shows to the next track, one back to the previous one, where
// the player can.
function skipTrack(player, step) {
    if (!player)
        return;
    if (step > 0 && player.canGoNext)
        player.next();
    else if (step < 0 && player.canGoPrevious)
        player.previous();
}
