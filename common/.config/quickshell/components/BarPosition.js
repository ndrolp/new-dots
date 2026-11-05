.pragma library

// What a Bar position means for what is laid out from the bar. Things are
// measured `along` the bar, from the left of a top or bottom bar and from the
// top of a side bar, and `away` from it, from the screen edge it sits on; this
// turns those measures into the screen's x and y. An unknown Bar position
// counts as top.

// Whether the bar runs down a side of the screen.
function sideBar(barPosition) {
    return barPosition === "left" || barPosition === "right";
}

// Whether going away from the bar goes against the screen's x or y.
function reversed(barPosition) {
    return barPosition === "bottom" || barPosition === "right";
}

// The { x, y } of a point `along` and `away`, in a box `depth` deep.
function point(barPosition, along, away, depth) {
    const across = reversed(barPosition) ? depth - away : away;

    return sideBar(barPosition) ? { x: across, y: along } : { x: along, y: across };
}

// The { x, y, width, height } of an { along, away, length, depth } area, in a box
// `boxDepth` deep.
function area(barPosition, part, boxDepth) {
    const corner = point(barPosition, part.along,
        reversed(barPosition) ? part.away + part.depth : part.away, boxDepth);

    return sideBar(barPosition)
        ? { x: corner.x, y: corner.y, width: part.depth, height: part.length }
        : { x: corner.x, y: corner.y, width: part.length, height: part.depth };
}

// The room around something, { top, right, bottom, left }, from the room `near`
// the bar, `far` from it and at both of its `ends` along the bar.
function sides(barPosition, near, far, ends) {
    const first = reversed(barPosition) ? far : near;
    const last = reversed(barPosition) ? near : far;

    return sideBar(barPosition)
        ? { top: ends, right: last, bottom: ends, left: first }
        : { top: first, right: ends, bottom: last, left: ends };
}
