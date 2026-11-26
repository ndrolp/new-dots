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

// The room along the bar between a bar element's edge and its content, at
// both ends.
var elementPadding = 8;

// The bar elements that show a lone glyph, drawn in a square pill
// (workspaceButtonSize long) while they draw their own.
var squareElements = Object.freeze(["network", "bluetooth", "tray"]);

// Whether bar element `element` draws its own pill: not while its pills are
// transparent, on a docked bar, inside a capsule
// (BarProfileModel.elementPillsDrawn), or in a group of two or more of the
// elements `isShown` says are shown, which draws one background for them all.
function drawsOwnPill(element, profile, isShown) {
    if (!BarProfileModel.elementPillsDrawn(profile))
        return false;
    const zone = BarProfileModel.elementZone(profile.barElements, element);
    return !BarProfileModel.zoneGroups(profile.barElements, zone, isShown)
        .some(group => group.length > 1 && group.indexOf(element) !== -1);
}

// How long bar element `element` is along the bar around its content,
// `contentLength` long: elementPadding at both ends, so what the elements
// show sits evenly apart and a capsule's row is centred on what it shows. A
// square element that draws its own pill keeps it square: the pills' edges
// are what sits evenly apart then. Takes the bar profile, with the bar
// elements it draws, and which of them are shown, `isShown(id)`.
function elementLength(element, contentLength, profile, isShown) {
    if (squareElements.indexOf(element) !== -1 && drawsOwnPill(element, profile, isShown))
        return profile.workspaceButtonSize;
    return contentLength + elementPadding * 2;
}
