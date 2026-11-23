import QtQuick

// The colorscheme selector inside a capsule (ThemeSelectorBody.qml), opened
// instead of the full-screen one on a monitor whose bar is a capsule. Each
// colorscheme selected is previewed, the capsule too; Enter applies it, and
// closing it any other way (Esc, a click outside, another popup) shows the
// active colorscheme again. Not built only while open, unlike the other
// capsule popups: the preview back to the active colorscheme runs as it
// closes, and must outlive its reveal.
BarPopup {
    id: root

    // The colorscheme selector module (modules/ThemeSelector.qml).
    required property var feature

    popup: "colorschemes"
    popupWidth: 640

    ThemeSelectorBody {
        width: parent.width
        appearance: root.appearance
        wallpapers: root.feature.wallpapers
        active: root.shown

        onCloseRequested: root.popups.popupClosed(root.popup)
    }
}
