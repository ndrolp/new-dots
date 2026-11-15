.pragma library
.import "../BarPosition.js" as BarPosition
.import "../../config/BarProfileModel.js" as BarProfileModel

// Where a popup opens in its bar window, from the Bar position: away from the
// bar, towards the inside of the screen; along the bar, centred on the bar
// element that opened it, whatever zone it sits in, shifted to stay on screen;
// at an end of the bar when its element isn't on the bar. Either way it keeps clear
// of the bar's rounded ends. On an opaque or docked bar popups are attached:
// they hang from the bar itself. On a transparent bar they float. On a capsule
// they are inside it: centred on it, right past its row, and the capsule grows
// round them.

// Takes the bar profile of the popup's monitor, { barStyle }.
function attached(bar) {
    return BarProfileModel.opaque(bar) || BarProfileModel.docked(bar);
}

// Whether popups open inside the capsule. Takes the bar profile, { barStyle }.
function inside(bar) {
    return BarProfileModel.capsule(bar);
}

// A popup inside a capsule placed as one floating right past the capsule's
// row, with no gap, and centred on the row whatever element opened it.
function insidePlacement(placement) {
    const capsule = placement.capsule;
    const sideBar = BarPosition.sideBar(placement.barPosition);

    return Object.assign({}, placement, {
        attached: false,
        spacing: 0,
        content: capsule,
        trigger: sideBar
            ? { start: capsule.y, length: capsule.height }
            : { start: capsule.x, length: capsule.width }
    });
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

// Where along the bar a popup of this length starts. `edge` is the end of the
// bar it opens at without a trigger: "left" or "right", the zones' names, so on
// a side bar left is the top and right the bottom.
function start(placement, popupLength, barLength) {
    const trigger = placement.trigger;
    const clear = margin(placement);
    const far = Math.max(clear, barLength - popupLength - clear);

    if (!trigger)
        return placement.edge === "left" ? clear : far;

    return Math.max(clear, Math.min(
        barLength - popupLength - clear,
        trigger.start + (trigger.length - popupLength) / 2
    ));
}

// How far the popup's near side is from the side of the bar window on the
// screen's edge.
function reach(placement) {
    const content = placement.content;

    if (placement.attached)
        return placement.thickness;

    if (!content)
        return placement.thickness + placement.spacing;

    const contentEnd = {
        top: content.y + content.height,
        bottom: placement.window.height - content.y,
        left: content.x + content.width,
        right: placement.window.width - content.x
    }[placement.barPosition];

    return contentEnd + placement.spacing;
}

// Takes { barPosition, popupWidth, popupHeight, restingHeight, edge, attached,
// window: { width, height } (the bar window), thickness (the bar's),
// padding, radius, spacing,
// trigger: { start, length } | null (the bar element, along the bar in bar
// window coordinates; null when it isn't on the bar),
// content: { x, y, width, height } | null (the bar content the elements sit in),
// inside (on a capsule), capsule: { x, y, width, height } (its row, in the bar
// window, when inside) }.
// `popupHeight` is the window's height and `restingHeight` what it would be
// without a hold (see PopupFrame.heldHeight), the same when left out.
// Returns the popup window's { x, y } in the bar window, the { start, end } the
// popup spans along the bar and `surfaceShift`, how far along the bar its surface
// sits from the start of the window. On a side bar a hold runs along the bar: a
// popup's place along it follows its resting length, and the window is placed
// for the held one, so it holds still around that whole stretch. No longer than
// that, a resting popup always fits inside it.
function position(given) {
    const placement = given.inside ? insidePlacement(given) : given;
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
// and the contents are as wide as on top. One inside a capsule leaves none: the
// capsule is drawn round it. Takes { barPosition, attached, inside, inset,
// joinRadius }.
function room(placement) {
    if (placement.inside)
        return { top: 0, right: 0, bottom: 0, left: 0 };

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
