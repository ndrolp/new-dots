.pragma library

// The bookmarks the quick search shows: at most two rows of five, in the
// order of the settings. The rest are reached only by typing.

var across = 5;
var maxRows = 2;

// The bookmarks whose label or URL holds `query` (case and surrounding
// spaces ignored), the first two rows of them.
function shown(bookmarks, query) {
    const needle = (query || "").trim().toLowerCase();
    return bookmarks.filter(bookmark =>
        (bookmark.label + " " + bookmark.url).toLowerCase().includes(needle))
        .slice(0, across * maxRows);
}

// The rows `count` shown bookmarks take.
function rows(count) {
    return Math.min(maxRows, Math.ceil(count / across));
}
