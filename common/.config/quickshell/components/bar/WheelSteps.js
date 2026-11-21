.pragma library

// Scrolling turned into steps, at most one per gesture: pure, no Quickshell.
// Down (what scrolls a list down) steps forward, +1; up steps back, -1.

// How far, in angleDelta units, a gesture goes before it steps: one notch.
const notch = 120;

// Qt's scroll phases (Qt.ScrollPhase): a wheel notch has none; a touchpad
// swipe begins, updates, ends, then may coast on with momentum.
const noPhase = 0;
const begin = 1;
const end = 3;
const momentum = 4;

// How long (ms) a touchpad that reports no phases pauses before its swipe
// counts as over.
const pause = 250;

// Where a run of wheel events starts: nothing scrolled, no step taken in
// the gesture under way, no event yet.
function initial() {
    return { scrolled: 0, stepped: false, last: -Infinity };
}

// What one wheel event (QML's WheelEvent: angleDelta, pixelDelta, phase)
// does at time `now` (ms), from `state`: { state, step }, step being -1, 0
// or +1. A wheel steps once per whole notch, never more per event; a
// touchpad swipe steps once, the first time it has gone a notch, and not
// again until the next swipe begins, its momentum included. A touchpad
// that reports no phases (pixel deltas, no phase) begins a swipe after a
// pause.
function take(state, wheel, now) {
    const phase = wheel.phase || noPhase;
    const swipe = phase !== noPhase || wheel.pixelDelta.y !== 0;
    const fresh = phase === begin || phase === end
        || (phase === noPhase && now - state.last > pause);
    const current = fresh ? initial() : state;

    if (phase === begin || phase === end || phase === momentum || current.stepped)
        return { state: Object.assign({}, current, { last: now }), step: 0 };

    const scrolled = current.scrolled + wheel.angleDelta.y;
    if (Math.abs(scrolled) < notch)
        return { state: { scrolled: scrolled, stepped: false, last: now }, step: 0 };
    return {
        // A swipe holds its step until it ends; a wheel is ready for the next notch.
        state: { scrolled: 0, stepped: swipe, last: now },
        step: scrolled < 0 ? 1 : -1
    };
}
