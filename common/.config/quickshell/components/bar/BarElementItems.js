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
// without one, the recording indicator while it isn't active and cava while
// silent; every other element is always shown when enabled. `status` says
// what there is: `live`, `expanded` (whether the capsule is), `player`,
// `recordings`, `keepAwakeOn` (see LiveElements.activeRules), `hasBattery`
// and `cavaSilent`.
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
    if (element === "recording")
        return LiveElements.active(element, status);
    if (element === "cava")
        return !status.cavaSilent;
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
