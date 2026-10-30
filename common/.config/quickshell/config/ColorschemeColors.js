.pragma library

// The active colorscheme's 16 colours, read from the active colorscheme's colours file
// (config/colors.json, a link to colorschemes/<name>/quickshell/colors.json
// set by the colorscheme changer). Every Theme shares one live copy, kept
// by ColorschemeColorsFile.qml, which reads the file again when the shell is
// asked to (`quickshell ipc call colorscheme reload`).

// everforestdark's, for when the file is missing or broken.
const fallback = Object.freeze({
    background: "#272e33",
    backgroundSecondary: "#1e2326",
    surface: "#374145",
    surfaceHover: "#414b50",
    border: "#4f5b58",
    accent: "#a7c080",
    accentHover: "#b8cc9e",
    green: "#a7c080",
    red: "#e67e80",
    orange: "#e69875",
    yellow: "#dbbc7f",
    purple: "#d699b6",
    blue: "#7fbbb3",
    text: "#d3c6aa",
    textMuted: "#9da9a0",
    textDisabled: "#7a8478"
});

const hexColour = /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/;

// The colours in a colours file's text: all 16, or everforestdark's when the
// text isn't JSON or any colour is missing or not a #rrggbb(aa) colour.
function fromJson(text) {
    let parsed;
    try {
        parsed = JSON.parse(text);
    } catch (error) {
        return fallback;
    }

    const colours = {};
    for (const name in fallback) {
        const value = parsed && parsed[name];
        if (typeof value !== "string" || !hexColour.test(value))
            return fallback;
        colours[name] = value;
    }
    return colours;
}

let live = null;

// The one live copy every Theme reads its colours from: an object whose
// `colours` changes when the colours file is read again. Outside a running
// shell (the tests) the file can't be read, and it stays everforestdark's.
function shared() {
    if (live === null) {
        const component = Qt.createComponent(Qt.resolvedUrl("ColorschemeColorsFile.qml"));
        live = component.status === 1 /* Component.Ready */ ? component.createObject(null) : null;
        if (live === null)
            live = { colours: fallback };
    }
    return live;
}
