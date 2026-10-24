.pragma library

// Where a popup opens in its bar window. Popups of center bar elements open
// under them, shifted sideways to stay on screen; the rest at the bar edge.

// The bar edge a popup opens at: "left" or "right".
function edgeX(placement, edge) {
    if (edge === "left")
        return placement.padding;

    return Math.max(placement.padding, placement.barWidth - placement.popupWidth - placement.padding);
}

// Takes { popupWidth, barWidth, padding, nearTrigger, edge,
// trigger: { x, width } | null (the bar element, in bar window coordinates) }.
function x(placement) {
    const trigger = placement.trigger;

    if (!placement.nearTrigger)
        return edgeX(placement, placement.edge);
    if (!trigger)
        return edgeX(placement, "right");

    return Math.max(placement.padding, Math.min(
        placement.barWidth - placement.popupWidth - placement.padding,
        trigger.x + (trigger.width - placement.popupWidth) / 2
    ));
}

// Takes { barHeight, spacing, nearTrigger,
// content: { y, height } | null (the bar content the elements sit in) }.
function y(placement) {
    const content = placement.content;

    if (placement.nearTrigger && content)
        return content.y + content.height + placement.spacing;

    return placement.barHeight + placement.spacing;
}
