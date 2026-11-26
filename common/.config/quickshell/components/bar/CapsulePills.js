.pragma library

// The capsule's workspace pills (CapsuleWorkspaceRow.qml), one per workspace
// of its monitor, at rest and expanded: how each looks and how big it is, at rest and expanded. Pure
// functions; they never mutate what they are given.

// What workspace `id` is to the pills of the monitor on `screen`: "shown",
// the one that monitor shows, whichever monitor has focus; "urgent", one
// asking for attention; "occupied", one with windows; or "empty".
// `workspaceService` is WorkspaceService.qml, or anything with
// activeWorkspaceIdForScreen, isUrgent and isOccupied.
function role(id, workspaceService, screen) {
    if (id === workspaceService.activeWorkspaceIdForScreen(screen))
        return "shown";
    if (workspaceService.isUrgent(id))
        return "urgent";
    return workspaceService.isOccupied(id) ? "occupied" : "empty";
}

// What a chip of workspace `id` shows: its glyph when the workspaces bar
// element's `options` use glyphs and have one for it, else its number.
function label(id, options) {
    const glyph = options.glyphsEnabled && options.glyphs.length >= id
        ? String(options.glyphs[id - 1]).trim() : "";
    return glyph !== "" ? glyph : String(id);
}

// How big the pill of a workspace of `role` is, { width, height }. At rest
// it is `pillDepth` deep and twice as long, the shown one twice that.
// Expanded, a chip is `chipDepth` deep and its label, `labelLength` long,
// plus half its depth on either side; the shown one is half a chip longer on
// either side. Takes { pillDepth, chipDepth, labelLength }.
function size(role, expanded, measures) {
    const shown = role === "shown";
    if (!expanded)
        return { width: measures.pillDepth * (shown ? 4 : 2), height: measures.pillDepth };
    return {
        width: measures.labelLength + measures.chipDepth * (shown ? 2 : 1),
        height: measures.chipDepth
    };
}
