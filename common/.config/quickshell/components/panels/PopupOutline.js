.pragma library

// The outline of an attached popup: square top corners, small curved corners
// joining it to the bar's bottom edge, and rounded bottom corners.

// How round its corners are at its current size, so they never cross while it
// unfolds. Takes { width, height, radius, joinRadius }; returns { join, bottom }.
function attachedCorners(outline) {
    const bottom = Math.max(0, Math.min(outline.radius, outline.height / 2, outline.width / 2));
    const join = Math.max(0, Math.min(outline.joinRadius, outline.height - bottom));

    return { join: join, bottom: bottom };
}
