.pragma library
.import "../Clamp.js" as Clamp
.import "../../config/BarProfileModel.js" as BarProfileModel

// How the capsule looks at rest and expanded (capsule bar style only). Pure,
// no Quickshell. Expanded it looks more solid, its `solidity` going from 0 at
// rest to 1 expanded on the capsule's spring (CapsuleSurface.qml), past 1 or
// below 0 mid-overshoot:
// - fillAlpha(alpha, solidity): its fill's opacity.
// - shadowRings(solidity): how dark each ring of its shadow is.
// "Expanded" here is its row showing its expanded view (looksExpanded), not
// merely the capsule held expanded; its clock then shows the date too
// (ClockText.js).

// Whether the capsule on `bar`, anything with { barStyle, capsuleRowExpanded
// }, looks expanded: solid, with the date on its clock. Only while its row
// shows its expanded view (the row crossfade's "expanded"): not with a popup
// inside, which sets the row at rest, nor while a change shows instead of it;
// never on any other bar style.
function looksExpanded(bar) {
    return BarProfileModel.capsule(bar) && bar.capsuleRowExpanded === true;
}

// How much more opaque, 0 to 1, the expanded capsule's fill is than the
// profile's opacity.
const expandedOpacity = 0.15;

// How dark each 1 px ring of its shadow is, from its edge outwards: at rest a
// few faint, fading pixels; expanded a little darker and two pixels further.
const restingRings = [0.14, 0.09, 0.05, 0.02, 0, 0];
const expandedRings = [0.18, 0.13, 0.09, 0.06, 0.03, 0.01];

// How dark each ring of its shadow is, from its edge outwards, as `solidity`
// goes from the resting rings to the expanded ones.
function shadowRings(solidity) {
    const t = Clamp.unit(solidity);
    return restingRings.map((resting, index) => resting + (expandedRings[index] - resting) * t);
}

// Its fill's opacity, 0 to 1, from the profile's `alpha`: that at rest, up to
// `expandedOpacity` more expanded, never past fully opaque.
function fillAlpha(alpha, solidity) {
    return Math.min(1, alpha + expandedOpacity * Clamp.unit(solidity));
}
