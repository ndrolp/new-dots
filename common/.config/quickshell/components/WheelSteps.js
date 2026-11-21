.pragma library

// Turns wheel events into steps: a mouse wheel steps once per notch, a
// touchpad gesture at most once however far it goes. Scrolling down steps
// forward (1), up back (-1). Pure: the caller keeps the state between events,
// starting from start(), and passes each event as
// { angleDelta, pixelDelta, phase, time } with the vertical deltas, the
// event's Qt.ScrollPhase and the time in milliseconds.

// One wheel notch, in angleDelta units.
const notch = 120;
// How long a scroll stays still before what follows is a new scroll, in
// milliseconds: for a touchpad that reports no phases, and for parts of a
// wheel notch.
const quietGap = 300;

function start() {
    return { travel: 0, stepped: false, last: -Infinity };
}

// { state, step }: the state to pass with the next event, and the step this
// event makes (1, -1 or 0).
function next(state, scroll) {
    // A gesture with phases runs from its begin to its end, however still
    // it stays in between.
    const quiet = scroll.phase === Qt.NoScrollPhase && scroll.time - state.last > quietGap;
    const now = quiet ? Object.assign(start(), { last: scroll.time })
        : Object.assign({}, state, { last: scroll.time });

    if (scroll.phase === Qt.ScrollBegin || scroll.phase === Qt.ScrollEnd)
        return { state: Object.assign(start(), { last: scroll.time }), step: 0 };
    if (scroll.phase === Qt.ScrollMomentum || now.stepped)
        return { state: now, step: 0 };

    now.travel += scroll.angleDelta;
    if (Math.abs(now.travel) < notch)
        return { state: now, step: 0 };

    const step = now.travel < 0 ? 1 : -1;
    // A gesture, with phases or from a touchpad without them, steps once; a
    // wheel steps again on its next notch.
    const gesture = scroll.phase === Qt.ScrollUpdate || scroll.pixelDelta !== 0;
    return { state: Object.assign(now, { travel: 0, stepped: gesture }), step: step };
}
