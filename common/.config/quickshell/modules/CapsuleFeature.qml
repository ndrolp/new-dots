import QtQuick
import "SwitchTo.js" as SwitchTo
import "OpenPopup.js" as OpenPopup

// A feature with a full-screen panel that, on a monitor whose bar is a
// capsule, opens inside the capsule instead, as the bar popup `popupName`
// (the wallpaper picker, the launcher, unified search, the clipboard). Where
// it opens is decided each time it opens, by the focused bar
// (OpenPopup.focusedCapsule); `open` is only the full-screen panel's.
Feature {
    id: root

    // The bar module, which opens and closes popups on the bars.
    required property var bar
    // The name of its popup inside a capsule.
    required property string popupName
    // Whether its popup is open inside a capsule.
    readonly property bool popupOpen: !!bar && bar.openPopup.popup === popupName
    // Open anywhere: full-screen or inside a capsule.
    readonly property bool shown: open || popupOpen

    // The focused bar's capsule, or null when it opens full-screen.
    function capsule() {
        return OpenPopup.focusedCapsule(bar.bars(), bar.focusedMonitor());
    }

    function toggle() {
        if (!available)
            return;
        if (shown)
            hide();
        else
            show();
    }

    function show() {
        if (!available)
            return;
        if (capsule() === null) {
            open = true;
            return;
        }
        open = false;
        bar.openPopup = OpenPopup.openedOnFocusedBar(bar.openPopup, popupName,
            bar.bars(), bar.focusedMonitor());
    }

    function hide() {
        open = false;
        if (popupOpen)
            bar.closePopup();
    }

    // Closes it, wherever it is open, and opens `other` in its place.
    function switchTo(other) {
        SwitchTo.switchTo(() => root.hide(), other);
    }
}
