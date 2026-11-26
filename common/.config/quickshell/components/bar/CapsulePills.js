.pragma library

// Which workspaces the capsule's workspace pills show (CapsuleWorkspaceRow.qml).
// Pure functions; they never mutate what they are given.

// Whether workspace `id` has a pill at rest: the active one does, empty or
// not, and every one with windows; an empty one has none. `workspaceService`
// is WorkspaceService.qml, or anything with isActive and isOccupied.
// Scrolling over the pills still goes through every workspace.
function hasRestingPill(id, workspaceService) {
    return workspaceService.isActive(id) || workspaceService.isOccupied(id);
}
