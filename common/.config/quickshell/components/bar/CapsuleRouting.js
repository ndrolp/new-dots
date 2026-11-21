.pragma library

// Which capsule acts: whether a capsule is expanded, which one SUPER+I
// toggles and where a change (volume, brightness, …) shows. Pure functions
// over the bars as modules/Bar.qml lists them; they never mutate them.

// Whether the capsule is expanded: while any of its causes holds it, given as
// { cause: bool }. Hovering it is one ("hover"); others join as more keys.
function expanded(causes) {
    return Object.keys(causes || {}).some(cause => causes[cause] === true);
}

// Whether a bar window's capsule is hidden: only a capsule, and only while
// its monitor's focused workspace has a real fullscreen window (not a
// maximized one), given as { capsule, fullscreen }. Other bar styles stay.
function hidden(bar) {
    return bar.capsule === true && bar.fullscreen === true;
}

// The focused monitor's bar, as `bars` list it, or undefined without one.
function barOnMonitor(bars, focusedMonitor) {
    return (bars || []).find(bar => bar.monitor === focusedMonitor);
}

// Whether a bar's capsule is available to act on (SUPER+I, a change, a new
// notification): there is a bar, it is shown and is a capsule not hidden for
// a fullscreen window. A popup inside doesn't change it; each use decides
// what that means. `bar` is { visible, capsule, capsuleHidden }, as
// modules/Bar.qml lists it, or undefined without one.
function capsuleAvailable(bar) {
    return !!bar && bar.visible === true && bar.capsule === true && bar.capsuleHidden !== true;
}

// The bar window SUPER+I expands or collapses: the focused monitor's, when its
// capsule is available (see capsuleAvailable); else null, and the toggle does
// nothing. `bars` are { window, monitor, visible, capsule, capsuleHidden }, as
// modules/Bar.qml lists them.
function toggledBar(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    return capsuleAvailable(bar) ? bar.window : null;
}

// Where a change (any of those in components/panels/OsdChange.js) shows, on
// the focused monitor only: { capsule: window } when its capsule is available
// (see capsuleAvailable), which expands to show it instead of the OSD; {}
// while a popup is inside that capsule, when it shows nowhere; else
// { osd: screen }, the OSD on the focused monitor's screen, also while its
// capsule is hidden for a fullscreen window, or on the first screen (null)
// when no bar is on it. `bars` are { window, monitor, screen, visible,
// capsule, popupInside, capsuleHidden }, as modules/Bar.qml lists them.
function changeTarget(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    if (!bar)
        return { osd: null };
    if (!capsuleAvailable(bar))
        return { osd: bar.screen };
    return bar.popupInside ? {} : { capsule: bar.window };
}

// Whether a new notification is announced: shown (as a toast or in the
// capsule) and played. Not with Do Not Disturb on, nor for a kept one sent
// again after a reload, which only rebuilds the history. `arrival` is
// { doNotDisturb, lastGeneration }.
function announced(arrival) {
    return !(arrival || {}).doNotDisturb && !(arrival || {}).lastGeneration;
}

// Whether a bar's capsule can hold new notifications: its capsule is
// available (see capsuleAvailable), its profile turns notifications in the
// capsule on and no popup or panel is inside. Once it can't, those it holds
// show as toasts. `bar` is { visible, capsule, capsuleHidden, popupInside,
// capsuleNotifications }.
function holdsNotifications(bar) {
    return capsuleAvailable(bar) && bar.capsuleNotifications === true && bar.popupInside !== true;
}

// Where a new notification shows: the focused monitor's capsule window, when
// it holds notifications (see holdsNotifications) and the notification is
// announced (see announced; `arrival` left out counts as announced); else
// null, a toast. `bars` are { window, monitor, visible, capsule, popupInside,
// capsuleHidden, capsuleNotifications }, as modules/Bar.qml lists them.
function notificationTarget(bars, focusedMonitor, arrival) {
    const bar = barOnMonitor(bars, focusedMonitor);
    return announced(arrival) && holdsNotifications(bar) ? bar.window : null;
}
