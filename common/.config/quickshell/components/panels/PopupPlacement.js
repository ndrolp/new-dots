.pragma library

// Where a popup opens in its bar window, from the Bar position: away from the
// bar, towards the inside of the screen; along the bar, centred on the bar
// element that opened it, whatever zone it sits in, shifted to stay on screen;
// at the bar edge when its element isn't on the bar. Either way it keeps clear
// of the bar's rounded ends. On an opaque or docked bar popups are attached:
// they hang from the bar itself.

// Takes the bar profile of the popup's monitor,
// { barTransparent, transparentBarSlanted }.
function attached(bar) {
    return !bar.barTransparent || !!bar.transparentBarSlanted;
}

// Whether a bar at this Bar position runs from the top of the screen down.
function vertical(barPosition) {
    return barPosition === "left" || barPosition === "right";
}

// A distance as an { x, y } offset pointing at the bar.
function towardsBar(barPosition, distance) {
    if (vertical(barPosition))
        return { x: barPosition === "left" ? -distance : distance, y: 0 };

    return { x: 0, y: barPosition === "top" ? -distance : distance };
}

// How close to the bar's ends a popup may open: the padding, or the bar's
// radius when its rounded ends reach further in.
function margin(placement) {
    return Math.max(placement.padding, placement.radius || 0);
}

// Where along the bar a popup of this length starts. `edge` is the bar edge it
// opens at without a trigger: "left" or "right", the zones' names, so on a side
// bar left is the top and right the bottom.
function start(placement, popupLength, barLength) {
    const trigger = placement.trigger;
    const side = margin(placement);
    const far = Math.max(side, barLength - popupLength - side);

    if (!trigger)
        return placement.edge === "left" ? side : far;

    return Math.max(side, Math.min(
        barLength - popupLength - side,
        trigger.start + (trigger.length - popupLength) / 2
    ));
}

// How far the popup's near side is from the side of the bar window on the
// screen's edge.
function reach(placement) {
    const content = placement.content;

    if (placement.attached)
        return placement.barHeight;

    if (!content)
        return placement.barHeight + placement.spacing;

    const contentEnd = {
        top: content.y + content.height,
        bottom: placement.window.height - content.y,
        left: content.x + content.width,
        right: placement.window.width - content.x
    }[placement.barPosition];

    return contentEnd + placement.spacing;
}

// Takes { barPosition, popupWidth, popupHeight, edge, attached,
// window: { width, height } (the bar window), barHeight (the bar's thickness),
// padding, radius, spacing,
// trigger: { start, length } | null (the bar element, along the bar in bar
// window coordinates; null when it isn't on the bar),
// content: { x, y, width, height } | null (the bar content the elements sit in) }.
// Returns the popup window's { x, y } in the bar window, and the { start, end }
// it spans along the bar.
function position(placement) {
    const away = reach(placement);

    if (vertical(placement.barPosition)) {
        const along = start(placement, placement.popupHeight, placement.window.height);

        return {
            x: placement.barPosition === "left" ? away : placement.window.width - away - placement.popupWidth,
            y: along,
            start: along,
            end: along + placement.popupHeight
        };
    }

    const along = start(placement, placement.popupWidth, placement.window.width);

    return {
        x: along,
        y: placement.barPosition === "top" ? away : placement.window.height - away - placement.popupHeight,
        start: along,
        end: along + placement.popupWidth
    };
}

// The room around the surface inside the popup window, { top, right, bottom,
// left }. A floating popup keeps the inset all around; an attached one touches
// the bar and leaves room only beside it, for the curved corners that join it
// to the bar. Takes { barPosition, attached, inset, joinRadius }.
function room(placement) {
    if (!placement.attached)
        return { top: placement.inset, right: placement.inset, bottom: placement.inset, left: placement.inset };

    const join = placement.joinRadius;

    if (vertical(placement.barPosition))
        return { top: join, right: 0, bottom: join, left: 0 };

    return { top: 0, right: join, bottom: 0, left: join };
}
