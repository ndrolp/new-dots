.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel
.import "../panels/ControlCenterNames.js" as Names

// Which of BarElementItems' elements are shown: pure, no Quickshell.

// Whether `element` is shown: it must be enabled in `barElements`, and the
// ones that can have nothing to show are hidden then. `status` says what
// there is: `hasPlayer`, `hasBattery`, `recording` and `cavaSilent`.
// Every other element, keep-awake among them, is always shown when enabled.
function itemVisible(element, barElements, status) {
    if (!BarProfileModel.elementEnabled(barElements, element))
        return false;
    if (element === "media")
        return status.hasPlayer;
    if (element === "battery")
        return status.hasBattery;
    if (element === "recording")
        return status.recording;
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
