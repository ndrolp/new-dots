.pragma library

// Wallpaper model: pure logic over wallpapers.json, no Quickshell. Wallpapers
// are assigned per monitor description, and each monitor only sees the folder
// of its orientation.

// Hyprland transforms 1 and 3 rotate the output a quarter turn; 0 and 2 keep
// it as it is. Flipped transforms fall back to the output size.
function isPortrait(transform, width, height) {
    const value = Number(transform);

    if (value === 1 || value === 3)
        return true;
    if (value === 0 || value === 2)
        return false;

    return height > width;
}

// `assignments` with `path` set for `monitorDescription`, as a fresh object.
// A monitor without a description is never assigned, and a stale assignment
// left under an empty description is dropped.
function withAssignment(assignments, monitorDescription, path) {
    const updated = Object.assign({}, assignments);
    delete updated[""];

    if (monitorDescription !== "")
        updated[monitorDescription] = path;

    return updated;
}

// The index `offset` steps away from `index`, wrapping around both ends.
function step(index, offset, count) {
    if (count === 0)
        return index;

    return (index + offset + count) % count;
}
