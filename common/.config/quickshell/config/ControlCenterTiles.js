.pragma library

// The control center's tiles: one global ordered list, stored in
// appearance.json as `controlCenterTiles` ([{ id, enabled }]) and not part of
// any bar profile. Pure logic, no Quickshell.

// Every tile, in the order a fresh config shows them: the quick tiles first.
const tileIds = [
    "wifi", "bluetooth", "doNotDisturb", "microphone", "keepAwake", "nightLight",
    "audioOutput", "lock", "displaysOff", "powerProfile", "screenCapture", "clipboard",
    "power", "capsLock"
];

// How many visible tiles the collapsed control center's row holds.
const collapsedRowSize = 6;

function defaultTiles() {
    return tileIds.map(id => ({ id: id, enabled: true }));
}

// The ids of the shown tiles, in order: what the expanded control center shows.
function visibleTiles(tiles) {
    return (tiles || []).filter(tile => tile.enabled !== false).map(tile => tile.id);
}

// The collapsed control center's row: the first visible tiles, at most
// collapsedRowSize.
function collapsedTiles(tiles) {
    return visibleTiles(tiles).slice(0, collapsedRowSize);
}

// `tiles` as the shell can show it, as a fresh list: tiles it no longer has
// and repeats are dropped, tiles missing from it are added, shown, at the end.
function completeTiles(tiles) {
    const complete = [];
    const seen = {};

    for (const tile of tiles || []) {
        if (!tile || tileIds.indexOf(tile.id) === -1 || seen[tile.id])
            continue;
        seen[tile.id] = true;
        complete.push({ id: tile.id, enabled: tile.enabled !== false });
    }

    for (const id of tileIds) {
        if (!seen[id])
            complete.push({ id: id, enabled: true });
    }

    return complete;
}

function setTileEnabled(tiles, id, enabled) {
    return completeTiles(tiles).map(tile => tile.id === id
        ? { id: tile.id, enabled: enabled } : tile);
}

// `id` swapped with the tile `offset` (-1 or 1) places away; past an end of
// the list nothing changes.
function moveTile(tiles, id, offset) {
    const moved = (tiles || []).map(tile => ({ id: tile.id, enabled: tile.enabled !== false }));
    const index = moved.findIndex(tile => tile.id === id);
    const target = index + offset;

    if (index === -1 || target < 0 || target >= moved.length)
        return moved;

    const tile = moved[index];
    moved[index] = moved[target];
    moved[target] = tile;
    return moved;
}

// The tile the "Collapsed row above" divider follows: the last one of the
// collapsed row once it is full; "" while fewer tiles are visible.
function dividerAfter(tiles) {
    const visible = visibleTiles(tiles);
    return visible.length >= collapsedRowSize ? visible[collapsedRowSize - 1] : "";
}
