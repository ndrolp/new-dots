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

// `assignments` with each monitor of `picked` ({ description: path }) set,
// as one fresh object, so they are saved together.
function withAssignments(assignments, picked) {
    let updated = assignments;
    for (const monitorDescription in picked)
        updated = withAssignment(updated, monitorDescription, picked[monitorDescription]);
    return updated;
}

// The index `offset` steps away from `index`, wrapping around both ends.
function step(index, offset, count) {
    if (count === 0)
        return index;

    return (index + offset + count) % count;
}

// The folder a wallpaper file is in.
function folderOf(path) {
    return path.slice(0, path.lastIndexOf("/"));
}

// The files of `listed` directly in `folder`.
function wallpapersIn(folder, listed) {
    return listed.filter(path => folderOf(path) === folder);
}

// The wallpaper folders for `colorscheme`, under `root`: its own Horizontal
// and Vertical folders, each falling back to Default's when `listed` (the
// files found in them) has none in it.
function colorschemeFolders(root, colorscheme, listed) {
    function folder(orientation) {
        const own = root + "/" + colorscheme + "/" + orientation;
        return wallpapersIn(own, listed).length > 0 ? own : root + "/Default/" + orientation;
    }

    return { horizontal: folder("Horizontal"), vertical: folder("Vertical") };
}

// A wallpaper for each monitor ({ description, portrait }), from those of its
// orientation, by `random` (0 ≤ r < 1): one no other monitor got while any is
// left. Monitors without a description, or without any wallpaper of their
// orientation, are left out.
function spread(monitors, horizontal, vertical, random) {
    const picked = {};
    const used = [];

    for (const monitor of monitors) {
        const wallpapers = monitor.portrait ? vertical : horizontal;
        if (monitor.description === "" || wallpapers.length === 0)
            continue;

        const unused = wallpapers.filter(path => !used.includes(path));
        const choices = unused.length > 0 ? unused : wallpapers;
        const path = choices[Math.min(choices.length - 1, Math.floor(random() * choices.length))];
        picked[monitor.description] = path;
        used.push(path);
    }

    return picked;
}
