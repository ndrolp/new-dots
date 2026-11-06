.pragma library

// The workspace overview's model: what it lists and how that fits on one
// screen. Pure logic, no Quickshell.

const firstWorkspace = 1;
const lastWorkspace = 21;

function isListed(id) {
    return id >= firstWorkspace && id <= lastWorkspace;
}

function physicalOrder(left, right) {
    return left.x - right.x || left.y - right.y;
}

// The connected monitor a Hyprland monitor selector means, if any: "desc:…"
// for its description, or its connector name.
function monitorMatching(monitors, selector) {
    const description = selector.startsWith("desc:") ? selector.slice(5) : null;

    return monitors.find(monitor => description !== null
        ? monitor.description === description : monitor.name === selector) || null;
}

// Workspace id to the connected monitor the rules from `hyprctl workspacerules
// -j` send it to. A rule for a monitor that isn't connected doesn't apply.
function ruledMonitors(rules, monitors) {
    const ruled = {};

    for (const rule of rules) {
        const monitor = rule.monitor && /^\d+$/.test(rule.workspaceString)
            ? monitorMatching(monitors, rule.monitor) : null;

        if (monitor !== null)
            ruled[rule.workspaceString] = monitor;
    }

    return ruled;
}

// Every monitor with its workspaces, in physical order, each workspace once.
//
// `monitors` are { name, description, x, y, workspaces } with the workspaces
// the shell assigns them, which may overlap; `existing` are the workspaces
// Hyprland has as { id, monitor } with the monitor's name; `rules` come from
// `hyprctl workspacerules -j`.
//
// An existing workspace goes under the monitor it's on. One that doesn't exist
// yet goes under the monitor the rules send it to, or the first monitor
// claiming it. Returns the monitors in order, with `workspaces` sorted and
// `newWorkspace` the number a new one there would take, or null.
function groups(monitors, existing, rules) {
    const ordered = monitors.slice().sort(physicalOrder);
    const ruled = ruledMonitors(rules, ordered);
    const owners = {};

    for (const workspace of existing) {
        if (isListed(workspace.id) && ordered.some(monitor => monitor.name === workspace.monitor))
            owners[workspace.id] = workspace.monitor;
    }

    for (const monitor of ordered) {
        for (const id of monitor.workspaces.filter(isListed)) {
            if (owners[id] === undefined)
                owners[id] = (ruled[id] || monitor).name;
        }
    }

    const listed = ordered.map(monitor => Object.assign({}, monitor, {
        workspaces: Object.keys(owners)
            .filter(id => owners[id] === monitor.name)
            .map(Number)
            .sort((left, right) => left - right)
    }));

    return listed.map(group => Object.assign({}, group, {
        newWorkspace: nextWorkspace(listed, group.name, ruled)
    }));
}

// How many tiles a monitor shows: its workspaces, and the new workspace tile
// while there's a number for it.
function tileCount(monitor) {
    return monitor.workspaces.length + (Number.isInteger(monitor.newWorkspace) ? 1 : 0);
}

// The largest tiles that show every monitor side by side on `width` × `height`
// with no scrolling. All monitors share one tile height and number of rows, and
// each tile keeps its monitor's proportions, so every row count is tried for
// the one that leaves the tiles largest.
//
// `monitors` are { name, width, height, workspaces, newWorkspace }; `spacing` is
// { tile, monitor, header, maxTileHeight }: the gap between tiles, the gap between
// monitors, the height of a monitor's header and an optional limit for a few
// workspaces.
// Returns { rows, tileHeight, width, height, monitors: [{ name, workspaces,
// newWorkspace, columns, tileWidth, width }] }, in the order given.
function layout(monitors, width, height, spacing) {
    if (monitors.length === 0)
        return { rows: 0, tileHeight: 0, width: 0, height: 0, monitors: [] };

    const counts = monitors.map(tileCount);
    const aspects = monitors.map(monitor => monitor.width / monitor.height);
    const limit = spacing.maxTileHeight === undefined ? Infinity : spacing.maxTileHeight;
    const freeWidth = columns => width - (monitors.length - 1) * spacing.monitor
        - columns.reduce((gaps, count) => gaps + Math.max(0, count - 1) * spacing.tile, 0);
    let best = null;

    for (let rows = 1; rows <= Math.max(1, ...counts); rows++) {
        const columns = counts.map(count => Math.ceil(count / rows));
        const tileWidths = columns.reduce((sum, count, index) => sum + count * aspects[index], 0);
        const fromWidth = tileWidths > 0 ? freeWidth(columns) / tileWidths : Infinity;
        const fromHeight = (height - spacing.header - (rows - 1) * spacing.tile) / rows;
        const tileHeight = Math.max(0, Math.floor(Math.min(fromWidth, fromHeight, limit)));

        if (best === null || tileHeight > best.tileHeight)
            best = { rows: rows, columns: columns, tileHeight: tileHeight };
    }

    const placed = monitors.map((monitor, index) => {
        const tileWidth = best.tileHeight * aspects[index];
        const columns = best.columns[index];

        return {
            name: monitor.name,
            workspaces: monitor.workspaces,
            newWorkspace: monitor.newWorkspace,
            columns: columns,
            tileWidth: tileWidth,
            width: columns * tileWidth + Math.max(0, columns - 1) * spacing.tile
        };
    });

    return {
        rows: best.rows,
        tileHeight: best.tileHeight,
        width: placed.reduce((sum, monitor) => sum + monitor.width, 0)
            + (monitors.length - 1) * spacing.monitor,
        height: spacing.header + best.rows * best.tileHeight + (best.rows - 1) * spacing.tile,
        monitors: placed
    };
}

// Where a window sits in its workspace's tile. `window` is { at, size } as
// Hyprland reports them, in logical pixels of the whole desktop; `monitor` is
// { x, y, width, height } in the same pixels, so already scaled and rotated;
// `tile` is { width, height }. A window past the monitor's edge stays past the
// tile's.
function miniature(window, monitor, tile) {
    const scaleX = tile.width / monitor.width;
    const scaleY = tile.height / monitor.height;

    return {
        x: (window.at[0] - monitor.x) * scaleX,
        y: (window.at[1] - monitor.y) * scaleY,
        width: window.size[0] * scaleX,
        height: window.size[1] * scaleY
    };
}

// Whether a window appears on a workspace's tile. `window` is what Hyprland
// reports for it, so nothing until it's been described; `focused` is the
// workspace you're on. A scratchpad window's workspace has a negative id, which
// is never a tile's. Of a window group, only the active window isn't hidden.
function isShownOn(window, workspace, focused) {
    return window.workspace?.id === workspace
        && !window.hidden
        && (!window.pinned || workspace === focused);
}

// Which windows draw over which in a tile. Hyprland's window list says nothing
// of it, so this is only the layers that always hold.
function stacking(window) {
    return window.fullscreen ? 2 : window.floating ? 1 : 0;
}

// The name a window's icon goes by.
function appClass(window) {
    return String(window.class || window.initialClass || "application").toLowerCase();
}

// The size a window is drawn at while dragged: its own proportions, `longest`
// pixels along its longer side. Square until Hyprland has reported a size.
function ghostSize(window, longest) {
    const size = window.size || [1, 1];
    const scale = longest / Math.max(size[0], size[1], 1);

    return { width: size[0] * scale, height: size[1] * scale };
}

// Whether a window can be picked up. A pinned one is on every workspace already.
function canDrag(window) {
    return !window.pinned;
}

// Whether dropping a window on a workspace would move it.
function movesTo(window, workspace) {
    return isListed(workspace) && window.workspace?.id !== workspace;
}

// The Hyprland dispatch moving a window to a workspace without following it,
// wherever the window or the workspace are. Null for anything but an address.
function moveDispatch(address, workspace) {
    if (!/^(?:0x)?[0-9a-f]+$/i.test(address))
        return null;

    const prefixed = address.startsWith("0x") ? address : "0x" + address;
    return "hl.dsp.window.move({ workspace = " + workspace
        + ", follow = false, window = \"address:" + prefixed + "\" })";
}

// The `hyprctl --batch` moving a window to a workspace that doesn't exist yet and
// leaving that workspace on `monitor`, without following it. Hyprland only makes
// a workspace for the window, on the focused monitor or the one a rule names,
// and one with nothing in it can't be sent anywhere, so it takes both steps. The
// new workspace isn't active, so sending it on changes no focus. Null for
// anything but an address and a monitor's name.
function newWorkspaceBatch(address, workspace, monitor) {
    const move = moveDispatch(address, workspace);

    if (move === null || !/^[\w.-]+$/.test(monitor))
        return null;

    return "dispatch " + move + " ; dispatch hl.dsp.workspace.move({ workspace = "
        + workspace + ", monitor = \"" + monitor + "\" })";
}

// Every workspace listed, reading across the monitors.
function workspaceIds(groups) {
    return groups.reduce((ids, group) => ids.concat(group.workspaces), []);
}

// The index of the monitor holding a workspace, or the first one.
function monitorHolding(groups, id) {
    return Math.max(0, groups.findIndex(group => group.workspaces.indexOf(id) !== -1));
}

// The workspace `offset` places from `selected` in `ids`, wrapping around at
// the ends. Starts from the first one if `selected` isn't listed.
function stepped(ids, selected, offset) {
    if (ids.length === 0)
        return selected;

    const index = Math.max(0, ids.indexOf(selected));
    return ids[((index + offset) % ids.length + ids.length) % ids.length];
}

// The number a new workspace on a monitor takes: the next one after the
// monitor's last, skipping numbers another monitor has and numbers `ruled`
// (from ruledMonitors) binds to another monitor, where Hyprland would put it.
// Null when none is left.
function nextWorkspace(groups, monitorName, ruled) {
    const group = groups.find(candidate => candidate.name === monitorName);
    const taken = workspaceIds(groups);
    const last = group && group.workspaces.length > 0 ? Math.max(...group.workspaces) : 0;

    for (let id = last + 1; id <= lastWorkspace; id++) {
        if (taken.indexOf(id) === -1 && (!ruled[id] || ruled[id].name === monitorName))
            return id;
    }

    return null;
}
