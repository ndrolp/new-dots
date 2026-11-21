.pragma library

// Which capsule acts: whether a capsule is expanded, which one SUPER+I
// toggles and where a change (volume, brightness, …) shows. Pure functions
// over the bars as modules/Bar.qml lists them; they never mutate them.

// Whether the capsule is expanded: while any of its causes holds it, given as
// { cause: bool }. Hovering it is one ("hover"); others join as more keys.
function expanded(causes) {
    return Object.keys(causes || {}).some(cause => causes[cause] === true);
}

// The focused monitor's bar, as `bars` list it, or undefined without one.
function barOnMonitor(bars, focusedMonitor) {
    return (bars || []).find(bar => bar.monitor === focusedMonitor);
}

// The bar window SUPER+I expands or collapses: the focused monitor's, when it
// is shown and is a capsule; else null, and the toggle does nothing. `bars`
// are { window, monitor, visible, capsule }, as modules/Bar.qml lists them.
function toggledBar(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    return bar && bar.visible && bar.capsule ? bar.window : null;
}

// Where a change (any of those in components/panels/OsdChange.js) shows, on
// the focused monitor only: { capsule: window } when it has a capsule shown,
// which expands to show it instead of the OSD; {} while a popup is inside
// that capsule, when it shows nowhere; else { osd: screen }, the OSD on the
// focused monitor's screen, or on the first screen (null) when no bar is on
// it. `bars` are { window, monitor, screen, visible, capsule,
// popupInside }, as modules/Bar.qml lists them.
function changeTarget(bars, focusedMonitor) {
    const bar = barOnMonitor(bars, focusedMonitor);
    if (!bar)
        return { osd: null };
    if (!bar.visible || !bar.capsule)
        return { osd: bar.screen };
    return bar.popupInside ? {} : { capsule: bar.window };
}
