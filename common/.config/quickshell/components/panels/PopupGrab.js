.pragma library

// The windows a popup's focus grab holds. When a grab starts Hyprland gives
// the keyboard to the first held surface of an unordered map, so to the bar
// or the popup by hash order, and the bar never passes it on. So the grab
// starts on the popup alone (`holding` false) and takes the bar in once it
// holds, which leaves the keyboard where it is and keeps bar elements
// clickable.
function windows(popup, bar, holding) {
    return holding ? [popup, bar] : [popup];
}
