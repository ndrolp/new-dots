.pragma library
.import "../BarPosition.js" as BarPosition

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

// A distance as an { x, y } offset pointing at the bar.
function towardsBar(barPosition, distance) {
    return BarPosition.point(barPosition, 0, -distance, 0);
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

// Takes { barPosition, popupWidth, popupHeight, restingHeight, edge, attached,
// window: { width, height } (the bar window), barHeight (the bar's thickness),
// padding, radius, spacing,
// trigger: { start, length } | null (the bar element, along the bar in bar
// window coordinates; null when it isn't on the bar),
// content: { x, y, width, height } | null (the bar content the elements sit in) }.
// `popupHeight` is the window's height and `restingHeight` what it would be
// without a hold (see PopupFrame.heldHeight), the same when left out.
// Returns the popup window's { x, y } in the bar window, the { start, end } the
// popup spans along the bar and `surfaceShift`, how far along the bar its surface
// sits from the start of the window. On a side bar a hold runs along the bar: a
// popup's place along it follows its resting length, and the window is placed
// for the held one, so it holds still around that whole stretch. No longer than
// that, a resting popup always fits inside it.
function position(placement) {
    const barPosition = placement.barPosition;
    const sideBar = BarPosition.sideBar(barPosition);
    const barLength = sideBar ? placement.window.height : placement.window.width;
    const length = sideBar ? placement.popupHeight : placement.popupWidth;
    const resting = !sideBar ? length
        : placement.restingHeight === undefined ? placement.popupHeight : placement.restingHeight;
    const along = start(placement, length, barLength);
    const restingStart = start(placement, resting, barLength);
    const area = BarPosition.area(barPosition, {
        along: along,
        away: reach(placement),
        length: length,
        depth: sideBar ? placement.popupWidth : placement.popupHeight
    }, sideBar ? placement.window.width : placement.window.height);

    return {
        x: area.x,
        y: area.y,
        start: restingStart,
        end: restingStart + resting,
        surfaceShift: restingStart - along
    };
}

// The room around the surface inside the popup window, { top, right, bottom,
// left }. A floating popup keeps the inset all around; an attached one touches
// the bar and leaves room only beside it, for the curved corners that join it
// to the bar. The window's width counts that room on any Bar position, so a side
// bar, whose joins are above and below it, leaves as much free on the far side
// and the contents are as wide as on top. Takes { barPosition, attached, inset,
// joinRadius }.
function room(placement) {
    if (!placement.attached)
        return { top: placement.inset, right: placement.inset, bottom: placement.inset, left: placement.inset };

    const join = placement.joinRadius;

    return BarPosition.sides(placement.barPosition, 0, BarPosition.sideBar(placement.barPosition) ? join * 2 : 0, join);
}

// The stretch of the bar an element takes, { start, length } in bar window
// coordinates. Takes the Bar position, the bar content the element sits in and
// its { x, y, width, height } there, or null when it isn't on the bar.
function triggerSpan(barPosition, content, element) {
    if (!element)
        return null;

    return BarPosition.sideBar(barPosition)
        ? { start: content.y + element.y, length: element.height }
        : { start: content.x + element.x, length: element.width };
}
