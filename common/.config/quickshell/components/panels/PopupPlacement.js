.pragma library

// Where a popup opens in its bar window: under the bar element that opened
// it, whatever zone it sits in, shifted sideways to stay on screen; at the bar
// edge when its element isn't on the bar. Either way it keeps clear of the
// bar's rounded ends. On an opaque bar popups are attached: they hang from the
// bar's bottom edge.

// Takes the bar profile of the popup's monitor, { barTransparent }.
function attached(bar) {
    return !bar.barTransparent;
}

// How close to the bar's ends a popup may open: the padding, or the bar's
// radius when its rounded ends reach further in.
function margin(placement) {
    return Math.max(placement.padding, placement.radius || 0);
}

// The bar edge a popup opens at: "left" or "right".
function edgeX(placement, edge) {
    const side = margin(placement);

    if (edge === "left")
        return side;

    return Math.max(side, placement.barWidth - placement.popupWidth - side);
}

// Takes { popupWidth, barWidth, padding, radius, edge,
// trigger: { x, width } | null (the bar element, in bar window coordinates;
// null when it isn't on the bar) }.
function x(placement) {
    const trigger = placement.trigger;

    if (!trigger)
        return edgeX(placement, placement.edge);

    const side = margin(placement);
    return Math.max(side, Math.min(
        placement.barWidth - placement.popupWidth - side,
        trigger.x + (trigger.width - placement.popupWidth) / 2
    ));
}

// Takes { barHeight, spacing, attached,
// content: { y, height } | null (the bar content the elements sit in) }.
function y(placement) {
    const content = placement.content;

    if (placement.attached)
        return placement.barHeight;

    if (content)
        return content.y + content.height + placement.spacing;

    return placement.barHeight + placement.spacing;
}

// The room around the surface inside the popup window. A floating popup keeps
// the inset all around; an attached one touches the bar and leaves room only
// beside it, for the curved corners that join it to the bar.
// Takes { attached, inset, joinRadius }.
function room(placement) {
    if (placement.attached)
        return { top: 0, side: placement.joinRadius, bottom: 0 };

    return { top: placement.inset, side: placement.inset, bottom: placement.inset };
}
