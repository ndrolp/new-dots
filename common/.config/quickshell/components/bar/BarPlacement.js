.pragma library
.import "../BarPosition.js" as BarPosition

// Where the bar sits on its screen, from its Bar position. Every function takes
// the bar profile of its monitor, or as much of it as it reads.

// The gap a floating bar keeps from the screen edge it sits on. The key still
// says top, but it applies from whichever edge that is.
function margin(bar) {
    return bar.barTransparent && !bar.transparentBarSlanted ? bar.transparentBarTopMargin : 0;
}

// The space the bar takes from its screen edge inwards. Also what it reserves,
// so windows stay clear of it.
function thickness(bar) {
    return bar.barHeight + margin(bar);
}

// The screen edges the bar's window is anchored to: its own and the two beside
// it, so that it runs the length of the screen.
function windowAnchors(barPosition) {
    return {
        top: barPosition !== "bottom",
        right: barPosition !== "left",
        bottom: barPosition !== "top",
        left: barPosition !== "right"
    };
}

// The room around the bar content in the bar's window: the margin on the
// screen's edge, nothing away from it and the padding at the bar's two ends,
// which a docked bar's zones reach. Returns { top, right, bottom, left }.
function contentMargins(bar) {
    const docked = bar.barTransparent && bar.transparentBarSlanted;
    const padding = docked ? 0 : bar.horizontalPadding;

    return BarPosition.sides(bar.barPosition, margin(bar), 0, padding);
}

// An opaque bar's bar border: a 1px line along its edge facing the desktop,
// left out where an attached popup hangs from it, so the popup's own border
// carries it on. Takes the Bar position, the bar window's { width, height } and
// that stretch { start, end } along the bar, or null. Returns the line's pieces,
// each { x, y, width, height } in the window.
function edgeBorder(barPosition, window, gap) {
    const sideBar = BarPosition.sideBar(barPosition);
    const length = sideBar ? window.height : window.width;
    const depth = sideBar ? window.width : window.height;
    const stretches = gap
        ? [{ start: 0, end: Math.min(length, gap.start) }, { start: Math.max(0, gap.end), end: length }]
        : [{ start: 0, end: length }];

    return stretches.filter(stretch => stretch.end > stretch.start).map(stretch =>
        BarPosition.area(barPosition, {
            along: stretch.start,
            away: depth - 1,
            length: stretch.end - stretch.start,
            depth: 1
        }, depth));
}
