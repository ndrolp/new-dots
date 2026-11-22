.pragma library
.import "../components/bar/CapsuleRouting.js" as CapsuleRouting
.import "OpenPopup.js" as OpenPopup

// Where the settings panel is: { where, window }. `where` is "closed",
// "centered" (its own window, centered on `window`'s screen) or "inside"
// (inside `window`'s capsule, as that bar's popup). Closed, `window` is the
// bar it was last on. `bars` are { window, monitor, visible, capsule,
// capsuleHidden }, as modules/Bar.qml lists them.

// The three values of a place's `where`.
var where = Object.freeze({ closed: "closed", centered: "centered", inside: "inside" });

var closed = Object.freeze({ where: where.closed, window: null });

// Opens it on the bar `window`: inside its capsule when that capsule is
// available (CapsuleRouting.capsuleAvailable), else centered.
function openedOn(window, bars) {
    const bar = (bars || []).find(candidate => candidate.window === window);
    return { where: CapsuleRouting.capsuleAvailable(bar) ? where.inside : where.centered, window: window };
}

// Whether it is open, wherever.
function isOpen(current) {
    return current.where !== where.closed;
}

// The settings button on the bar `window`: closes it if it is open on that
// bar, else opens it there (openedOn), moving it from any other bar.
function toggledOn(current, window, bars) {
    if (isOpen(current) && current.window === window)
        return { where: where.closed, window: window };
    return openedOn(window, bars);
}

// Opened by IPC or another panel: on the focused monitor's bar
// (OpenPopup.focusedBar), or centered on the bar it was last on when no bar
// is shown.
function shown(current, bars, focusedMonitor) {
    const window = OpenPopup.focusedBar(bars || [], focusedMonitor);
    if (window === null)
        return { where: where.centered, window: current.window };
    return openedOn(window, bars);
}

// IPC's toggle: closes it wherever it is open, else opens it (shown).
function toggled(current, bars, focusedMonitor) {
    if (isOpen(current))
        return { where: where.closed, window: current.window };
    return shown(current, bars, focusedMonitor);
}

// The bar style of the profile its bar draws changed live (or a pending style
// change was discarded): open inside a capsule that is no longer one, it moves
// to the centered position; open centered on a bar whose capsule is now
// available (CapsuleRouting.capsuleAvailable), it moves inside. It stays open
// either way, and closed it stays closed.
function followed(current, bars) {
    if (!isOpen(current))
        return current;
    const bar = (bars || []).find(candidate => candidate.window === current.window);
    if (current.where === where.inside && !(bar && bar.capsule === true))
        return { where: where.centered, window: current.window };
    if (current.where === where.centered && CapsuleRouting.capsuleAvailable(bar))
        return { where: where.inside, window: current.window };
    return current;
}
