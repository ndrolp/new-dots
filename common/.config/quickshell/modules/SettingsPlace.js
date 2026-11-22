.pragma library
.import "../components/bar/CapsuleRouting.js" as CapsuleRouting
.import "OpenPopup.js" as OpenPopup

// Where the settings panel is: { where, window }. `where` is "closed",
// "centered" (its own window, centered on `window`'s screen) or "inside"
// (inside `window`'s capsule, as that bar's popup). Closed, `window` is the
// bar it was last on. `bars` are { window, monitor, visible, capsule,
// capsuleHidden }, as modules/Bar.qml lists them.

var closed = Object.freeze({ where: "closed", window: null });

// Opens it on the bar `window`: inside its capsule when that capsule is
// available (CapsuleRouting.capsuleAvailable), else centered.
function openedOn(current, window, bars) {
    const bar = (bars || []).find(candidate => candidate.window === window);
    return { where: CapsuleRouting.capsuleAvailable(bar) ? "inside" : "centered", window: window };
}

// Whether it is open, wherever.
function isOpen(current) {
    return current.where !== "closed";
}

// The settings button on the bar `window`: closes it if it is open on that
// bar, else opens it there (openedOn), moving it from any other bar.
function toggledOn(current, window, bars) {
    if (isOpen(current) && current.window === window)
        return { where: "closed", window: window };
    return openedOn(current, window, bars);
}

// Opened by IPC or another panel: on the focused monitor's bar
// (OpenPopup.focusedBar), or centered on the bar it was last on when no bar
// is shown.
function shown(current, bars, focusedMonitor) {
    const window = OpenPopup.focusedBar(bars || [], focusedMonitor);
    if (window === null)
        return { where: "centered", window: current.window };
    return openedOn(current, window, bars);
}

// IPC's toggle: closes it wherever it is open, else opens it (shown).
function toggled(current, bars, focusedMonitor) {
    if (isOpen(current))
        return { where: "closed", window: current.window };
    return shown(current, bars, focusedMonitor);
}
