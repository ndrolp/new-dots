.pragma library
.import "../BarPosition.js" as BarPosition
.import "../../config/BarProfileModel.js" as BarProfileModel

// Where the bar sits on its screen, from its Bar position. Every function takes
// the bar profile of its monitor, or as much of it as it reads.

// The gap a floating bar or a capsule keeps from the screen edge it sits on.
// The key still says top, but it applies from whichever edge that is.
function margin(bar) {
    return BarProfileModel.transparent(bar) || BarProfileModel.capsule(bar)
        ? bar.transparentBarTopMargin : 0;
}

// How deep a capsule's workspace pills are.
var workspacePillDepth = 4;

// How deep a capsule's workspace chips are, its pills grown while it is
// expanded: a little more than the profile's text size.
function workspaceChipDepth(bar) {
    return bar.textSize + 2;
}

// How far a capsule reaches past its row of bar elements, away from its
// screen edge, to hold its workspace pills: the pills and the profile's
// spacing past them. Nothing on any other bar style.
function workspaceStrip(bar) {
    return BarProfileModel.capsule(bar) ? workspacePillDepth + bar.spacing : 0;
}

// The room a capsule keeps inside it across the bar, on both sides of its
// contents: between its screen-side edge and its row, and past its workspace
// pills. Nothing on any other bar style.
function capsulePadding(bar) {
    return BarProfileModel.capsule(bar) ? (bar.capsuleVerticalPadding || 0) : 0;
}

// The room a capsule keeps inside it at its two ends along the bar, past its
// row and its pill row: half again the profile's horizontal padding, so its
// round ends never crowd what they hold. There is no setting of its own.
function capsuleEndPadding(bar) {
    return bar.horizontalPadding * 1.5;
}

// The space the bar takes from its screen edge inwards: on a capsule, its
// workspace pills and its vertical padding included.
function thickness(bar) {
    return bar.barHeight + margin(bar) + workspaceStrip(bar) + capsulePadding(bar) * 2;
}

// The space the bar reserves from its screen edge, so windows stay clear of
// it: its thickness, and on a capsule whatever its live elements add to the
// depth of its workspace pills while they show collapsed, `liveDepth` the
// depth of the deepest of them (0 with none).
function reservedSpace(bar, liveDepth) {
    return thickness(bar)
        + (BarProfileModel.capsule(bar) ? Math.max(0, liveDepth - workspacePillDepth) : 0);
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
// screen's edge (on a capsule with its vertical padding), nothing away from
// it and the padding at the bar's two ends, which a docked bar's zones reach.
// Returns { top, right, bottom, left }.
function contentMargins(bar) {
    const padding = BarProfileModel.docked(bar) ? 0 : bar.horizontalPadding;

    return BarPosition.sides(bar.barPosition, margin(bar) + capsulePadding(bar), 0, padding);
}

// Where the bar content sits in the bar window, { x, y, width, height }:
// inside its margins (contentMargins), against the bar's screen edge and as
// deep as the bar's thickness leaves it, whatever the window's depth. So a
// capsule's window, grown away from its edge for a popup inside, leaves the
// content where it was. Takes the bar window's { width, height }.
function contentArea(bar, window) {
    const margins = contentMargins(bar);
    // A capsule's workspace pills, and its padding past them, are past its
    // row, outside the bar content.
    const depth = thickness(bar) - workspaceStrip(bar) - capsulePadding(bar);

    if (BarPosition.sideBar(bar.barPosition)) {
        const width = depth - margins.left - margins.right;
        return {
            x: bar.barPosition === "right" ? window.width - margins.right - width : margins.left,
            y: margins.top,
            width: width,
            height: window.height - margins.top - margins.bottom
        };
    }

    const height = depth - margins.top - margins.bottom;
    return {
        x: margins.left,
        y: bar.barPosition === "bottom" ? window.height - margins.bottom - height : margins.top,
        width: window.width - margins.left - margins.right,
        height: height
    };
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
