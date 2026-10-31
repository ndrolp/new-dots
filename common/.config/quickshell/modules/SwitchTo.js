.pragma library

// One part of the shell opening another in its place (Feature.switchTo, the
// control center's tiles): `closeThis` closes the current part, then
// `other.show()` opens the other one. When `other`'s plugin is off
// (`other.available` false) nothing happens and the current part stays open.
function switchTo(closeThis, other) {
    if (!other.available)
        return;

    closeThis();
    other.show();
}
