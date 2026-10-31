import Quickshell
import Quickshell.Io
import QtQuick
import "SwitchTo.js" as SwitchTo
import "OpenPopup.js" as OpenPopup
import "../components/panels/ControlCenterNames.js" as Names

// The control center is the bell's popup (components/panels/ControlCenterPopup.qml),
// opened on the focused monitor's bar; this module owns everything else
// about it. It is handed down, as one object, through the bar to the popup
// and its controls: the services they show, whether the controls are on
// (`controlsEnabled`, the plugin), and the stage. It holds the stage, the
// `control-center` IPC call (SUPER+C) and the shortcut logic SUPER+N shares
// (`toggle`), and opens the panels its tiles ask for (`openPanel`):
// clipboard, power menu and capture close it and open in its place, unless
// their plugin is off; the pencil opens the settings panel at its section.
// The audio output tile opens a subpage inside it.
Scope {
    id: root

    // The bar module, which opens and closes popups on the bars.
    required property var bar
    required property var plugins
    // The global appearance: do not disturb is a global setting.
    required property var appearance
    // The settings panel, for the pencil.
    required property var settings
    // What its notifications and controls show.
    required property var notificationHistory
    required property var screenCapture
    required property var clipboardHistory
    required property var systemMonitor
    required property var keepAwake
    required property var nightLight
    // The features its tiles open.
    required property var clipboardSelector
    required property var powerMenu
    required property var screenCaptureChooser

    // Off: the control center is notifications only, with no controls.
    readonly property bool available: plugins.controlCenterEnabled
    readonly property bool controlsEnabled: available
    // The stage it is at while open (the popup reports its handle and audio
    // output tile switching it), and the one it takes the next time it opens.
    property string stage: Names.controlCenter.collapsed

    // SUPER+N asks for "collapsed", SUPER+C for "expanded": closed, it opens
    // at that stage on the focused bar; open at the other stage, it switches
    // in place; open at that one, it closes (OpenPopup.controlCenterShortcut).
    // With the plugin off it just opens and closes.
    function toggle(preferred) {
        const next = OpenPopup.controlCenterShortcut(bar.openPopup, stage, preferred,
            bar.bars(), bar.focusedMonitor(), controlsEnabled);
        // The stage first: an opening reads it.
        stage = next.stage;
        bar.openPopup = next.open;
    }

    // Opens it expanded on the focused bar, or keeps it open there (quick
    // settings' button, through Feature.switchTo).
    function show() {
        stage = Names.controlCenter.expanded;
        bar.openPopup = OpenPopup.openedOnFocusedBar(bar.openPopup, Names.controlCenter.popup,
            bar.bars(), bar.focusedMonitor());
    }

    function toggleDoNotDisturb() {
        appearance.doNotDisturb = !appearance.doNotDisturb;
    }

    // A tile asked for `panel` (a Names.controlCenter panel name).
    function openPanel(panel) {
        if (panel === Names.controlCenter.clipboard)
            switchTo(clipboardSelector);
        else if (panel === Names.controlCenter.powerMenu)
            switchTo(powerMenu);
        else if (panel === Names.controlCenter.screenCapture)
            switchTo(screenCaptureChooser);
        else if (panel === Names.controlCenter.tileSettings)
            openTileSettings();
    }

    // A tile opens `other` in its place.
    function switchTo(other) {
        SwitchTo.switchTo(() => root.bar.closePopup(), other);
    }

    // The pencil closes it and opens the settings panel at its section, on
    // the same bar.
    function openTileSettings() {
        const window = bar.openPopup.window;
        bar.closePopup();
        if (window)
            settings.openSectionOn("ControlCenter", window.screen, window);
    }

    Connections {
        target: root.bar

        // The bell opens it collapsed (closing it keeps whatever stage it
        // is at, so it doesn't flash collapsed first).
        function onBarElementOpening(popup) {
            if (popup === Names.controlCenter.popup)
                root.stage = Names.controlCenter.collapsed;
        }
    }

    IpcHandler {
        target: "control-center"

        function toggle() {
            root.toggle(Names.controlCenter.expanded);
        }
    }
}
