.pragma library

// Which colorscheme preview the colorscheme selector runs. Pure, no Quickshell.
// One preview runs at a time; one asked for while another runs waits for it,
// and only the latest one asked for runs next. The state is
// { requested, running }: the colorscheme last asked for (or shown), and the
// one whose preview is running ("" when none is). Each function returns the
// new state and `start`, the colorscheme to preview now ("" for none).

const idle = Object.freeze({ requested: "", running: "" });

// `colorscheme` is already on screen (the active one, when the selector
// opens): asking for it runs nothing.
function shown(state, colorscheme) {
    return { state: { requested: colorscheme, running: state.running }, start: "" };
}

// A preview of `colorscheme` is asked for.
function requested(state, colorscheme) {
    if (colorscheme === "" || colorscheme === state.requested)
        return { state: state, start: "" };
    if (state.running !== "")
        return { state: { requested: colorscheme, running: state.running }, start: "" };
    return { state: { requested: colorscheme, running: colorscheme }, start: colorscheme };
}

// The running preview has finished: the one asked for meanwhile, if any, runs.
function exited(state) {
    if (state.requested !== "" && state.requested !== state.running)
        return { state: { requested: state.requested, running: state.requested }, start: state.requested };
    return { state: { requested: state.requested, running: "" }, start: "" };
}
