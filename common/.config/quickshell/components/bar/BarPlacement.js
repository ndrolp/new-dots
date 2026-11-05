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
