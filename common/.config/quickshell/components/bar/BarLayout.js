.pragma library
.import "../BarPosition.js" as BarPosition
.import "../../config/BarProfileModel.js" as BarProfileModel

// Where things sit in the bar, measured along it: from the left on a top or
// bottom bar, from the top on a side bar. `bar` is { barPosition, width, height,
// spacing, groupPadding, groupInset, endPadding, groupGap, groupBackgrounds }:
// the Bar position, the size of the bar content, the room between elements,
// the room inside a group along the bar and across it, the room kept at the
// bar's ends, and how a group is told apart (see groupLook). Without a Bar position it lays out like a top bar.

function barLength(bar) {
    return BarPosition.sideBar(bar.barPosition) ? bar.height : bar.width;
}

// How much of the bar an item takes up.
function itemLength(bar, item) {
    return BarPosition.sideBar(bar.barPosition) ? item.height : item.width;
}

// How a bar profile's groups are laid out, as the bar BarLayout measures takes
// it: the `spacing` between elements, the room inside a group along the bar
// (`groupPadding`) and across it (`groupInset`), the `groupGap` between a group
// and what is beside it, and whether a group draws its shared background
// (`groupBackgrounds`). Inside a capsule, its elements' only background, a
// group draws none and takes no room for one: it is told apart by a gap twice
// the spacing instead.
function groupLook(profile) {
    const capsule = BarProfileModel.capsule(profile);
    return {
        spacing: profile.spacing,
        groupPadding: capsule ? 0 : profile.groupHorizontalPadding,
        groupInset: profile.groupVerticalPadding,
        groupGap: capsule ? profile.spacing * 2 : profile.spacing,
        groupBackgrounds: !capsule
    };
}

// Takes the bar, a zone's groups of shown elements in order (see
// BarProfileModel.zoneGroups) and each element's length along the bar. Returns its elements' `positions`, { start, grouped } by element
// id, one { start, length } per group of two or more in `backgrounds` (none
// when the bar's `groupBackgrounds` is false), and its `length`, all relative
// to the zone's start. A group of two or more sits the bar's `groupGap` (the
// spacing without one) from what is beside it; lone elements, the spacing.
function zone(bar, groups, lengthOf) {
    const positions = {};
    const backgrounds = [];
    const groupGap = bar.groupGap === undefined ? bar.spacing : bar.groupGap;
    let end = 0;

    for (let groupIndex = 0; groupIndex < groups.length; groupIndex++) {
        const group = groups[groupIndex];
        const grouped = group.length > 1;
        const gap = grouped || (groupIndex > 0 && groups[groupIndex - 1].length > 1)
            ? groupGap : bar.spacing;
        const start = groupIndex > 0 ? end + gap : 0;

        end = start + (grouped ? bar.groupPadding : 0);
        for (let index = 0; index < group.length; index++) {
            if (index > 0)
                end += bar.spacing;
            positions[group[index]] = { start: end, grouped: grouped };
            end += lengthOf(group[index]);
        }

        if (grouped) {
            end += bar.groupPadding;
            if (bar.groupBackgrounds !== false)
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
    return BarPosition.sideBar(bar.barPosition)
        ? { x: centred(bar.width, item.width), y: start }
        : { x: start, y: centred(bar.height, item.height) };
}

// Where a group's background goes: its stretch of the bar, across the bar's
// thickness but for the group inset on either side.
function groupBackground(bar, start, length) {
    const sideBar = BarPosition.sideBar(bar.barPosition);
    const thickness = sideBar ? bar.width : bar.height;
    const inset = Math.max(0, Math.min(bar.groupInset || 0, (thickness - 1) / 2));

    return sideBar
        ? { x: inset, y: start, width: bar.width - inset * 2, height: length }
        : { x: start, y: inset, width: length, height: bar.height - inset * 2 };
}

// How thick a bar element is across the bar. Takes the bar profile.
function elementThickness(profile) {
    return !BarProfileModel.opaque(profile)
        ? profile.workspaceButtonSize + profile.pillVerticalPadding * 2
        : Math.max(1, profile.barHeight - profile.elementVerticalPadding * 2);
}

// The { width, height } of something `length` long along the bar and `thickness`
// across it. Takes the bar profile, or anything else with the Bar position.
// Whatever turns with the bar sizes itself through this.
function size(bar, length, thickness) {
    return BarPosition.sideBar(bar.barPosition)
        ? { width: thickness, height: length }
        : { width: length, height: thickness };
}

// How far long text turns: on either side bar it reads down the bar, so it
// isn't mirrored and its start stays at the top. Turning a row of text centred
// in its element keeps it centred there. Takes the bar profile.
function turn(bar) {
    return BarPosition.sideBar(bar.barPosition) ? 90 : 0;
}

// Where `area`, relative to a `box` that turns with the bar, ends up in the
// box's parent. Both are { x, y, width, height } as laid out before turning.
function turnedArea(bar, box, area) {
    if (!BarPosition.sideBar(bar.barPosition))
        return { x: box.x + area.x, y: box.y + area.y, width: area.width, height: area.height };

    const centre = { x: box.x + box.width / 2, y: box.y + box.height / 2 };
    return {
        x: centre.x + box.height / 2 - area.y - area.height,
        y: centre.y - box.width / 2 + area.x,
        width: area.height,
        height: area.width
    };
}

// How much of the screen `screen` runs along the bar. Takes the bar profile.
function screenLength(bar, screen) {
    return BarPosition.sideBar(bar.barPosition) ? screen.height : screen.width;
}

// What opens a popup, { x, y, width, height } in the bar: the whole bar element,
// or `area`, the part of it that did, relative to the element.
function trigger(item, area) {
    return area
        ? { x: item.x + area.x, y: item.y + area.y, width: area.width, height: area.height }
        : { x: item.x, y: item.y, width: item.width, height: item.height };
}
