.pragma library

// The volume as text, wherever it is shown (the audio bar element without its
// meter, the control center, quick settings): pure logic, no Quickshell.
// `volume` is the Pipewire volume, 1 being 100%. Volumes over 100% are shown
// as they are.
function percentage(volume) {
    return Math.round(volume * 100) + "%";
}
