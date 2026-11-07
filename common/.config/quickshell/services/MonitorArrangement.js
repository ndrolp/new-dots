.pragma library

// Where monitors sit: every rectangle { id, x, y, width, height } touching another, edge to edge,
// with no gaps and no overlaps. Sizes are logical pixels. Pure, no Quickshell.

// How close, in logical pixels, a monitor has to come to lining up with an edge of its neighbour
// for it to line up exactly.
const alignWithin = 64;

// Two monitors share at least this much edge, so a pointer can cross from one to the other.
const leastShared = 100;

function overlapsOnAxis(aStart, aLength, bStart, bLength) {
    return Math.min(aStart + aLength, bStart + bLength) - Math.max(aStart, bStart);
}

function overlap(a, b) {
    return overlapsOnAxis(a.x, a.width, b.x, b.width) > 0 && overlapsOnAxis(a.y, a.height, b.y, b.height) > 0;
}

function touching(a, b) {
    const sideBySide = a.x + a.width === b.x || b.x + b.width === a.x;
    const stacked = a.y + a.height === b.y || b.y + b.height === a.y;
    return (sideBySide && overlapsOnAxis(a.y, a.height, b.y, b.height) > 0)
        || (stacked && overlapsOnAxis(a.x, a.width, b.x, b.width) > 0);
}

// The monitors reachable from `first`, each touching another.
function reachable(rects, first) {
    const found = [first];
    for (let i = 0; i < found.length; i++) {
        rects.forEach(rect => {
            if (found.indexOf(rect) === -1 && touching(found[i], rect))
                found.push(rect);
        });
    }
    return found;
}

// Where `start`, `length` long, goes along the edge of a neighbour: as near as it can stay to where
// it was asked for while sharing some edge, lined up with the neighbour's ends when close to them.
function alongEdge(start, length, neighbourStart, neighbourLength) {
    const shared = Math.min(leastShared, length, neighbourLength);
    const lowest = neighbourStart - length + shared;
    const highest = neighbourStart + neighbourLength - shared;
    const kept = Math.max(lowest, Math.min(highest, start));
    const ends = [neighbourStart, neighbourStart + neighbourLength - length];
    const lined = ends.sort((a, b) => Math.abs(a - kept) - Math.abs(b - kept))[0];
    return Math.abs(lined - kept) <= alignWithin ? lined : kept;
}

function moved(rect, dx, dy) {
    return Object.assign({}, rect, { x: rect.x + dx, y: rect.y + dy });
}

// The smallest move from (dx, dy) that leaves `group` touching `fixed` with no overlap.
function nearestPlacement(group, fixed, dx, dy) {
    const placements = [];
    group.forEach(rect => fixed.forEach(neighbour => {
        const across = alongEdge(rect.y + dy, rect.height, neighbour.y, neighbour.height) - rect.y;
        const along = alongEdge(rect.x + dx, rect.width, neighbour.x, neighbour.width) - rect.x;
        placements.push({ dx: neighbour.x + neighbour.width - rect.x, dy: across });
        placements.push({ dx: neighbour.x - rect.width - rect.x, dy: across });
        placements.push({ dx: along, dy: neighbour.y + neighbour.height - rect.y });
        placements.push({ dx: along, dy: neighbour.y - rect.height - rect.y });
    }));
    const clear = placements.filter(placement => !group.some(rect => fixed.some(neighbour =>
        overlap(moved(rect, placement.dx, placement.dy), neighbour))));
    const distance = placement => Math.hypot(placement.dx - dx, placement.dy - dy);
    return clear.sort((a, b) => distance(a) - distance(b))[0];
}

// Brings every monitor out of reach of the first back to touching, nearest first.
function joined(rects) {
    let main = reachable(rects, rects[0]);
    let rest = rects.filter(rect => main.indexOf(rect) === -1);
    while (rest.length > 0) {
        const group = reachable(rest, rest[0]);
        const placement = nearestPlacement(group, main, 0, 0);
        main = main.concat(group.map(rect => moved(rect, placement.dx, placement.dy)));
        rest = rest.filter(rect => group.indexOf(rect) === -1);
        main = reachable(main.concat(rest), main[0]).filter(rect => rest.indexOf(rect) === -1);
    }
    return main;
}

// With the top left corner of them all at 0,0, in the order given.
function atOrigin(rects, order) {
    const left = Math.min(...rects.map(rect => rect.x));
    const top = Math.min(...rects.map(rect => rect.y));
    return order.map(wanted => {
        const rect = rects.filter(candidate => candidate.id === wanted.id)[0];
        return moved(rect, -left, -top);
    });
}

// `rects` with no gaps left between them.
function closed(rects) {
    return rects.length === 0 ? [] : atOrigin(joined(rects), rects);
}

// `rects` with `id` dropped at (x, y): it snaps to the nearest place touching the others, and they
// close up any gap it left. A monitor resized in place is dropped where it is, which makes room for
// it the same way.
function snapped(rects, id, x, y) {
    const dropped = rects.filter(rect => rect.id === id)[0];
    const others = rects.filter(rect => rect.id !== id);
    if (others.length === 0)
        return atOrigin([dropped], rects);

    const stayed = dropped.x === x && dropped.y === y;
    if (stayed && others.some(other => overlap(dropped, other)))
        return resized(rects, dropped, others);

    const rest = joined(others);
    const placement = nearestPlacement([dropped], rest, x - dropped.x, y - dropped.y);
    return atOrigin([moved(dropped, placement.dx, placement.dy)].concat(rest), rects);
}

// A monitor that grew where it stands keeps its place, and whatever it now overlaps moves off it.
function resized(rects, grown, others) {
    const clear = others.filter(other => !overlap(grown, other));
    const pushed = others.filter(other => overlap(grown, other));
    let settled = [grown].concat(clear);
    pushed.forEach(other => {
        const placement = nearestPlacement([other], settled, 0, 0);
        settled = settled.concat([moved(other, placement.dx, placement.dy)]);
    });
    return atOrigin(joined(settled), rects);
}

// Where a monitor turning on goes: past the right of the others, level with the top.
function nextSlot(rects) {
    if (rects.length === 0)
        return { x: 0, y: 0 };
    return { x: Math.max(...rects.map(rect => rect.x + rect.width)), y: Math.min(...rects.map(rect => rect.y)) };
}
