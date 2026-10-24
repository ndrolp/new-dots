.pragma library

// Where a popup opens in its bar window. Popups of center bar elements open
// under them, shifted sideways to stay on screen; the rest at the bar edge.
// On an opaque bar popups are attached: they hang from the bar's bottom edge.

// Takes the bar profile of the popup's monitor, { barTransparent }.
function attached(bar) {
    return !bar.barTransparent;
}

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

// Takes { barHeight, spacing, nearTrigger, attached,
// content: { y, height } | null (the bar content the elements sit in) }.
function y(placement) {
    const content = placement.content;

    if (placement.attached)
        return placement.barHeight;

    if (placement.nearTrigger && content)
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

// Where the Control center opens: centered at the top of its monitor,
// attached like a popup on an opaque bar, floating below a transparent one or
// at the top of a monitor without a bar.
// Takes { barVisible, barTransparent, barHeight (the bar window's), spacing }.
function controlCenter(placement) {
    if (!placement.barVisible)
        return { attached: false, y: placement.spacing };

    const isAttached = attached(placement);
    return {
        attached: isAttached,
        y: isAttached ? placement.barHeight : placement.barHeight + placement.spacing
    };
}
