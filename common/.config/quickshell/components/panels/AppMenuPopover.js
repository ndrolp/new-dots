.pragma library

// The app menu popover (SUPER+A) as plain data. Pure, no Quickshell.

// The popover's one list, from AppMenuModel's menus: the first menu's (the
// app-name menu's) items, then every other menu as a submenu, so menus added
// to the model show up here on their own.
function items(menus) {
    if (menus.length === 0)
        return [];

    const others = menus.slice(1)
        .map(menu => ({ kind: "submenu", label: menu.title, items: menu.items }));

    return others.length > 0
        ? menus[0].items.concat([{ kind: "separator" }], others)
        : menus[0].items;
}

// Where along one axis: just after the cursor, or just before it when that
// would run past the far edge, kept `margin` inside the monitor.
function along(cursor, size, length, margin) {
    const start = cursor + size <= length - margin ? cursor : cursor - size;

    return Math.max(margin, Math.min(start, length - size - margin));
}

// Where the popover opens, in the monitor's coordinates: at the cursor
// (`cursor` in Hyprland's global coordinates), down and to the right of it
// unless that runs off `screen` ({ x, y, width, height }).
function position(placement) {
    const screen = placement.screen;

    return {
        x: along(placement.cursor.x - screen.x, placement.width, screen.width, placement.margin),
        y: along(placement.cursor.y - screen.y, placement.height, screen.height, placement.margin)
    };
}
