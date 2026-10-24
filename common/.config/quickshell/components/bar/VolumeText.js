.pragma library

// The audio bar element's volume text, shown when its volume meter is off:
// pure logic, no Quickshell. `volume` is the Pipewire volume, 1 being 100%.
// Volumes over 100% are shown as they are.
function percentage(volume) {
    return Math.round(volume * 100) + "%";
}
