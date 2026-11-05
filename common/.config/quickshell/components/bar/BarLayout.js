.pragma library
.import "../panels/PopupPlacement.js" as PopupPlacement

// Where things sit in the bar, measured along it: from the left on a top or
// bottom bar, from the top on a side bar. `bar` is { barPosition, width, height,
// spacing, groupPadding, endPadding }: the Bar position, the size of the bar
// content, the room between groups and inside one, and the room kept at the
// bar's ends. Without a Bar position it lays out like a top bar.

function vertical(bar) {
    return PopupPlacement.vertical(bar.barPosition);
}

function barLength(bar) {
    return vertical(bar) ? bar.height : bar.width;
}

// How much of the bar an item takes up.
function itemLength(bar, item) {
    return vertical(bar) ? item.height : item.width;
}

// Takes the bar, a zone's groups of shown elements in order (see
// BarProfileModel.zoneGroups) and each element's length along the bar. Returns its elements' `positions`, { start, grouped } by element
// id, one { start, length } per group of two or more in `backgrounds`, and
// its `length`, all relative to the zone's start.
function zone(bar, groups, lengthOf) {
    const positions = {};
    const backgrounds = [];
    let end = 0;

    for (let groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        const group = groups[groupIndex];
        const grouped = group.length > 1;
        const start = groupIndex > 0 ? end + bar.spacing : 0;

        end = start + (grouped ? bar.groupPadding : 0);
        for (let index = 0; index < group.length; index++) {
            if (index > 0)
                end += bar.spacing;
            positions[group[index]] = { start: end, grouped: grouped };
            end += lengthOf(group[index]);
        }

        if (grouped) {
            end += bar.groupPadding;
            backgrounds.push({ start: start, length: end - start });
        }
    }

    return { positions: positions, backgrounds: backgrounds, length: end };
}

// Where a zone of this length starts. "left" and "right" are the bar's ends, so
// on either side bar left is the top and right the bottom; anything else is
// centred.
function zoneStart(bar, zoneName, zoneLength) {
    if (zoneName === "left")
        return bar.endPadding;
    if (zoneName === "right")
        return barLength(bar) - zoneLength - bar.endPadding;
    return Math.round((barLength(bar) - zoneLength) / 2);
}

// The middle of a size, the way anchors find it.
function middle(size) {
    return Math.trunc(size) % 2 ? (size + 1) / 2 : size / 2;
}

// How far in an item starts when centred, on the same pixel as an item anchored
// to the centre.
function centred(outer, inner) {
    return Math.round(middle(outer) - middle(inner));
}

// Where an { width, height } item goes: `start` along the bar, centred across it.
function place(bar, start, item) {
    return vertical(bar)
        ? { x: centred(bar.width, item.width), y: start }
        : { x: start, y: centred(bar.height, item.height) };
}

// Where a group's background goes: its stretch of the bar, across the whole
// thickness.
function groupBackground(bar, start, length) {
    return vertical(bar)
        ? { x: 0, y: start, width: bar.width, height: length }
        : { x: start, y: 0, width: length, height: bar.height };
}

// How thick a bar element is across the bar. Takes the bar profile.
function elementThickness(profile) {
    return profile.barTransparent
        ? profile.workspaceButtonSize + profile.pillVerticalPadding * 2
        : Math.max(1, profile.barHeight - profile.elementVerticalPadding * 2);
}

// The { width, height } of something `length` long along the bar and `thickness`
// across it. Takes the bar profile, or anything else with the Bar position.
// Whatever turns with the bar sizes itself through this.
function size(bar, length, thickness) {
    return vertical(bar)
        ? { width: thickness, height: length }
        : { width: length, height: thickness };
}

// What opens a popup, { x, y, width, height } in the bar: the whole bar element,
// or `area`, the part of it that did, relative to the element.
function trigger(item, area) {
    return area
        ? { x: item.x + area.x, y: item.y + area.y, width: area.width, height: area.height }
        : { x: item.x, y: item.y, width: item.width, height: item.height };
}
