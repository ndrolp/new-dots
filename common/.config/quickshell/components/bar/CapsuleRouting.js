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

// The bar window SUPER+I expands or collapses: the focused monitor's, when it
// is shown and is a capsule not hidden for a fullscreen window; else null, and
// the toggle does nothing. `bars` are { window, monitor, visible, capsule,
// capsuleHidden }, as modules/Bar.qml lists them.
function toggledBar(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    return bar && bar.visible && bar.capsule && !bar.capsuleHidden ? bar.window : null;
}

// Where a change (volume, brightness, Caps Lock, audio output, bar profile or
// keep-awake) shows, on the focused monitor only: { capsule: window } when it
// has a capsule shown, which expands to show it instead of the OSD; {} while a
// popup is inside that capsule, when it shows nowhere; else { osd: screen },
// the OSD on the focused monitor's screen, also while its capsule is hidden
// for a fullscreen window, or on the first screen (null) when no bar is on
// it. `bars` are { window, monitor, screen, visible, capsule, popupInside,
// capsuleHidden }, as modules/Bar.qml lists them.
function changeTarget(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    if (!bar)
        return { osd: null };
    if (!bar.visible || !bar.capsule || bar.capsuleHidden)
        return { osd: bar.screen };
    return bar.popupInside ? {} : { capsule: bar.window };
}
