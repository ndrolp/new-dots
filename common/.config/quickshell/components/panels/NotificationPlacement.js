.pragma library

// Where the toasts sit, from their location setting ("top-left",
// "bottom-center"…) and the bar profile of their monitor. The compositor lays
// them out inside the area the monitor's bar leaves free, so this knows nothing
// about the bar: the anchors pick the sides and the margins are plain gaps from
// that area. Anchored to neither left nor right, they center in it.
// Returns { anchors, margins }, each as { top, right, bottom, left }.
function place(location, profile) {
    const bottom = location.indexOf("bottom") === 0;
    const right = location.indexOf("right") !== -1;
    const left = location.indexOf("left") !== -1;

    return {
        anchors: { top: !bottom, right: right, bottom: bottom, left: left },
        margins: {
            top: bottom ? 0 : profile.spacing,
            right: right ? profile.horizontalPadding : 0,
            bottom: bottom ? profile.spacing : 0,
            left: left ? profile.horizontalPadding : 0
        }
    };
}
