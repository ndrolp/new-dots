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

// { state, step }: the state to pass with the next event, and the step
// `event` makes (1, -1 or 0). `updated` is `state` once `event` is counted.
function next(state, event) {
    // A gesture with phases runs from its begin to its end, however still
    // it stays in between.
    const quiet = event.phase === Qt.NoScrollPhase && event.time - state.last > quietGap;
    const updated = quiet ? Object.assign(start(), { last: event.time })
        : Object.assign({}, state, { last: event.time });

    if (event.phase === Qt.ScrollBegin || event.phase === Qt.ScrollEnd)
        return { state: Object.assign(start(), { last: event.time }), step: 0 };
    if (event.phase === Qt.ScrollMomentum || updated.stepped)
        return { state: updated, step: 0 };

    updated.travel += event.angleDelta;
    if (Math.abs(updated.travel) < notch)
        return { state: updated, step: 0 };

    const step = updated.travel < 0 ? 1 : -1;
    // A gesture, with phases or from a touchpad without them, steps once; a
    // wheel steps again on its next notch.
    const gesture = event.phase === Qt.ScrollUpdate || event.pixelDelta !== 0;
    return { state: Object.assign(updated, { travel: 0, stepped: gesture }), step: step };
}
