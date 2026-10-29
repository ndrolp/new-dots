.pragma library
.import "../../config/BarProfileModel.js" as BarProfileModel

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
