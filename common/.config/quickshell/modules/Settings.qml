import Quickshell
import Quickshell.Io
import QtQuick
import "../components/panels" as Panels
import "OpenPopup.js" as OpenPopup
import "SettingsPlace.js" as SettingsPlace
import "../config/BarProfileModel.js" as BarProfileModel

// The settings panel. On a monitor whose bar is a capsule it opens inside the
// capsule, as that bar's popup (components/panels/SettingsPopup.qml); on any
// other bar, or while that capsule is hidden for a fullscreen window, it opens
// centered on the bar's screen. A bar's settings button opens it on that bar;
// IPC and other panels on the focused monitor's bar (SettingsPlace.js). A
// live bar style change on its bar moves it between the two (followed), and
// it keeps what it shows (`view`) across the move. `open` is only the
// centered panel's.
Feature {
    id: root

    required property var appearance
    required property var monitors
    required property var monitorSetups
    required property var wallpapers
    required property var bookmarks
    required property var plugins
    required property var cava
    // The bar module, which opens and closes popups on the bars.
    required property var bar

    property var screen: null
    // The bar it is open on, or was last on.
    property var window: null
    // What the shown panel shows (ConfigPanel.view): its section, search
    // text and scroll position. The panel it moves to, or opens as, comes up
    // showing it; pending bar profile changes live in the appearance.
    property var view: ({})
    // The bar it is on draws a capsule: a live bar style change (or a
    // discarded one) flips it, and the panel follows.
    readonly property bool windowCapsule: !!window && !!window.barAppearance
        && BarProfileModel.capsule(window.barAppearance)
    // Set while go() moves it, which already placed it for its bar's style.
    property bool moving: false

    // Whether it is open inside a capsule.
    readonly property bool popupOpen: !!bar && bar.openPopup.popup === OpenPopup.settings
    // Open anywhere: centered or inside a capsule.
    readonly property bool shown: open || popupOpen

    // Asked to show `section` while open.
    signal sectionRequested(string section)

    // Where it is now, as SettingsPlace.js takes it.
    function place() {
        if (popupOpen)
            return { where: "inside", window: bar.openPopup.window };
        return { where: open ? "centered" : "closed", window: window };
    }

    // Moves it to `next` (a SettingsPlace.js place).
    function go(next) {
        moving = true;
        if (next.window)
            window = next.window;
        if (window)
            screen = window.screen;
        open = next.where === "centered";
        if (next.where === "inside")
            bar.openPopup = { popup: OpenPopup.settings, window: next.window };
        else if (popupOpen)
            bar.closePopup();
        moving = false;
    }

    onOpenChanged: {
        if (open && screen === null)
            screen = Quickshell.screens.values[0];
        // The centered panel comes up showing what the panel showed last.
        if (open)
            panelWindowItem.restoreView(view);
    }

    onWindowCapsuleChanged: {
        if (moving || !bar)
            return;
        const current = place();
        const next = SettingsPlace.followed(current, bar.bars());
        if (next.where !== current.where)
            go(next);
    }

    // The settings button on a bar: closes the panel if it is open on that
    // bar, otherwise opens it there.
    function toggleOn(barScreen, panelWindow) {
        go(SettingsPlace.toggledOn(place(), panelWindow, bar.bars()));
    }

    // Opens the panel on that bar at `section`, or shows `section` if it is
    // already open there.
    function openSectionOn(section, barScreen, panelWindow) {
        root.view = Object.assign({}, root.view, { section: section, scroll: 0 });
        panelWindowItem.openSection(section);
        go(SettingsPlace.openedOn(place(), panelWindow, bar.bars()));
        sectionRequested(section);
    }

    // IPC: closes it wherever it is open, else opens it on the focused bar.
    function toggle() {
        if (!available)
            return;
        go(SettingsPlace.toggled(place(), bar.bars(), bar.focusedMonitor()));
    }

    // Another panel opens it in its place, on the focused bar.
    function show() {
        go(SettingsPlace.shown(place(), bar.bars(), bar.focusedMonitor()));
    }

    // A bar came up: the panel attaches to the first one until asked from
    // another.
    function offerWindow(barScreen, panelWindow) {
        if (window !== null)
            return;

        screen = barScreen;
        window = panelWindow;
    }

    Panels.ConfigPanelWindow {
        id: panelWindowItem

        appearance: root.appearance
        monitors: root.monitors
        monitorSetups: root.monitorSetups
        wallpapers: root.wallpapers
        bookmarks: root.bookmarks
        plugins: root.plugins
        cava: root.cava
        open: root.open
        targetWindow: root.window

        onCloseRequested: root.open = false
        onViewChanged: {
            if (root.open)
                root.view = view;
        }
    }

    IpcHandler {
        target: "config"

        function toggle() {
            root.toggle();
        }
    }
}
