.pragma library
.import "../../services/WorkspaceState.js" as WorkspaceState

// The workspace overview's model: what it lists and how that fits on one
// screen. Pure logic, no Quickshell.

// The gaps between miniatures and between monitors, and a monitor's header.
const spacing = { miniature: 10, monitor: 32, header: 30 };

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
function monitorsWithWorkspaces(monitors, existing, rules) {
    const ordered = monitors.slice().sort(physicalOrder);
    const ruled = ruledMonitors(rules, ordered);
    const owners = {};

    for (const workspace of existing) {
        if (WorkspaceState.isListed(workspace.id) && ordered.some(monitor => monitor.name === workspace.monitor))
            owners[workspace.id] = workspace.monitor;
    }

    for (const monitor of ordered) {
        for (const id of monitor.workspaces.filter(WorkspaceState.isListed)) {
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

    return listed.map(monitor => Object.assign({}, monitor, {
        newWorkspace: nextWorkspace(listed, monitor.name, ruled)
    }));
}

// Whether a monitor shows the new workspace slot: only with a number left for it.
function hasSlot(monitor) {
    return Number.isInteger(monitor.newWorkspace);
}

// How many places a monitor's workspaces take: a miniature for each, and the
// new workspace slot while there's a number for it.
function slotCount(monitor) {
    return monitor.workspaces.length + (hasSlot(monitor) ? 1 : 0);
}

// The largest miniatures that show every monitor side by side on `width` ×
// `height` with no scrolling. All monitors share one miniature height and number
// of rows, and each miniature keeps its monitor's proportions, so every row count
// is tried for the one that leaves the miniatures largest.
//
// `monitors` are { width, height, workspaces, newWorkspace, … }; `spacing` is
// { miniature, monitor, header }, as in `spacing` above; a few workspaces stop
// growing at `maxMiniatureHeight`.
// Returns { rows, miniatureHeight, width, height, monitors: [{ monitor, columns,
// miniatureWidth, width }] }, in the order given, each `monitor` as it was given.
function layout(monitors, width, height, spacing, maxMiniatureHeight) {
    if (monitors.length === 0)
        return { rows: 0, miniatureHeight: 0, width: 0, height: 0, monitors: [] };

    const counts = monitors.map(slotCount);
    const aspects = monitors.map(monitor => monitor.width / monitor.height);
    const freeWidth = columns => width - (monitors.length - 1) * spacing.monitor
        - columns.reduce((gaps, count) => gaps + Math.max(0, count - 1) * spacing.miniature, 0);
    let best = null;

    for (let rows = 1; rows <= Math.max(1, ...counts); rows++) {
        const columns = counts.map(count => Math.ceil(count / rows));
        const miniatureWidths = columns.reduce((sum, count, index) => sum + count * aspects[index], 0);
        const fromWidth = miniatureWidths > 0 ? freeWidth(columns) / miniatureWidths : Infinity;
        const fromHeight = (height - spacing.header - (rows - 1) * spacing.miniature) / rows;
        const miniatureHeight = Math.max(0, Math.floor(Math.min(fromWidth, fromHeight, maxMiniatureHeight)));

        if (best === null || miniatureHeight > best.miniatureHeight)
            best = { rows: rows, columns: columns, miniatureHeight: miniatureHeight };
    }

    const placed = monitors.map((monitor, index) => {
        const miniatureWidth = best.miniatureHeight * aspects[index];
        const columns = best.columns[index];

        return {
            monitor: monitor,
            columns: columns,
            miniatureWidth: miniatureWidth,
            width: columns * miniatureWidth + Math.max(0, columns - 1) * spacing.miniature
        };
    });

    return {
        rows: best.rows,
        miniatureHeight: best.miniatureHeight,
        width: placed.reduce((sum, monitor) => sum + monitor.width, 0)
            + (monitors.length - 1) * spacing.monitor,
        height: spacing.header + best.rows * best.miniatureHeight + (best.rows - 1) * spacing.miniature,
        monitors: placed
    };
}

// Where a window sits in its workspace's miniature. `window` is { at, size } as
// Hyprland reports them, in logical pixels of the whole desktop; `monitor` is
// { x, y, width, height } in the same pixels, so already scaled and rotated;
// `miniature` is { width, height }. A window past the monitor's edge stays past
// the miniature's.
function windowBox(window, monitor, miniature) {
    const scaleX = miniature.width / monitor.width;
    const scaleY = miniature.height / monitor.height;

    return {
        x: (window.at[0] - monitor.x) * scaleX,
        y: (window.at[1] - monitor.y) * scaleY,
        width: window.size[0] * scaleX,
        height: window.size[1] * scaleY
    };
}

// Which windows draw over which in a miniature. Hyprland's window list says nothing
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
    return WorkspaceState.isListed(workspace) && window.workspace?.id !== workspace;
}

// What a key does, by the name WorkspaceOverview.qml acts on, or null for nothing.
// During a drag the keys that would go somewhere wait for it to end, and Esc
// cancels only the drag.
function keyAction(key, dragging) {
    switch (key) {
    case Qt.Key_Right: return "next";
    case Qt.Key_Left: return "previous";
    case Qt.Key_Down: return "rowDown";
    case Qt.Key_Up: return "rowUp";
    case Qt.Key_Home: return "first";
    case Qt.Key_End: return "last";
    case Qt.Key_Escape: return dragging ? "cancelDrag" : "close";
    case Qt.Key_N:
    case Qt.Key_Plus: return dragging ? null : "create";
    case Qt.Key_Return:
    case Qt.Key_Enter:
    case Qt.Key_Space: return dragging ? null : "activate";
    default: return null;
    }
}

// Every workspace listed, reading across the monitors.
function workspaceIds(monitors) {
    return monitors.reduce((ids, monitor) => ids.concat(monitor.workspaces), []);
}

// The index of the monitor holding a workspace, or the first one.
function monitorHolding(monitors, id) {
    return Math.max(0, monitors.findIndex(monitor => monitor.workspaces.indexOf(id) !== -1));
}

// The workspace `offset` places from `selected` in `ids`, wrapping around at
// the ends. Starts from the first one if `selected` isn't listed.
function stepped(ids, selected, offset) {
    if (ids.length === 0)
        return selected;

    const index = Math.max(0, ids.indexOf(selected));
    return ids[((index + offset) % ids.length + ids.length) % ids.length];
}

// The workspace selected after a keyAction of moving the selection, from
// `selected`. `placed` is `monitors` from layout. -1 is no selection.
function selectionAfter(action, placed, selected) {
    const monitors = placed.map(entry => entry.monitor);
    const ids = workspaceIds(monitors);

    if (action === "next" || action === "previous")
        return stepped(ids, selected, action === "next" ? 1 : -1);

    if (action === "first" || action === "last")
        return ids.length > 0 ? ids[action === "first" ? 0 : ids.length - 1] : -1;

    if (placed.length === 0)
        return selected;

    const row = placed[monitorHolding(monitors, selected)];
    return stepped(row.monitor.workspaces, selected, (action === "rowDown" ? 1 : -1) * row.columns);
}

// The number a new workspace on a monitor takes: the next one after the
// monitor's last, skipping numbers another monitor has and numbers `ruled`
// (from ruledMonitors) binds to another monitor, where Hyprland would put it.
// Null when none is left.
function nextWorkspace(monitors, monitorName, ruled) {
    const monitor = monitors.find(candidate => candidate.name === monitorName);
    const taken = workspaceIds(monitors);
    const last = monitor && monitor.workspaces.length > 0 ? Math.max(...monitor.workspaces) : 0;

    for (let id = last + 1; id <= WorkspaceState.lastWorkspace; id++) {
        if (taken.indexOf(id) === -1 && (!ruled[id] || ruled[id].name === monitorName))
            return id;
    }

    return null;
}
