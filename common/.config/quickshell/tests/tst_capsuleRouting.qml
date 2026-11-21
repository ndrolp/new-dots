import QtQuick
import QtTest
import "../components/bar/CapsuleRouting.js" as CapsuleRouting

// Which capsule acts: whether it is expanded, which one SUPER+I toggles and
// where a change shows.
TestCase {
    name: "CapsuleRouting"

    // Any one cause holds the capsule expanded: hovering it, and the causes
    // later tickets add (SUPER+I, a popup inside, a change being shown).
    function test_anyCauseHoldsTheCapsuleExpanded_data() {
        return [
            { tag: "none", causes: {}, expanded: false },
            { tag: "all off", causes: { hover: false, toggled: false }, expanded: false },
            { tag: "hover", causes: { hover: true }, expanded: true },
            { tag: "another", causes: { hover: false, popupInside: true }, expanded: true }
        ];
    }

    function test_anyCauseHoldsTheCapsuleExpanded(data) {
        compare(CapsuleRouting.expanded(data.causes), data.expanded);
    }

    // A capsule hides while its monitor's focused workspace has a fullscreen
    // window; other bar styles never do.
    function test_aCapsuleHidesForAFullscreenWindow_data() {
        return [
            { tag: "capsule, fullscreen", capsule: true, fullscreen: true, hidden: true },
            { tag: "capsule", capsule: true, fullscreen: false, hidden: false },
            { tag: "other bar style, fullscreen", capsule: false, fullscreen: true, hidden: false }
        ];
    }

    function test_aCapsuleHidesForAFullscreenWindow(data) {
        compare(CapsuleRouting.hidden({ capsule: data.capsule, fullscreen: data.fullscreen }), data.hidden);
    }

    // The bars as modules/Bar.qml lists them: one per monitor, each a window.
    function capsuleBars() {
        return [
            { window: "left window", monitor: "Left", visible: true, capsule: false },
            { window: "middle window", monitor: "Middle", visible: true, capsule: true },
            { window: "hidden window", monitor: "Hidden", visible: false, capsule: true },
            { window: "fullscreen window", monitor: "Fullscreen", visible: true, capsule: true,
                capsuleHidden: true }
        ];
    }

    // SUPER+I acts on the focused monitor's capsule.
    function test_theToggleActsOnTheFocusedMonitorsCapsule() {
        compare(CapsuleRouting.toggledBar(capsuleBars(), "Middle"), "middle window");
    }

    // On a focused monitor with a normal bar, a hidden one or none, it does
    // nothing: no other monitor's capsule stands in for it.
    function test_theToggleDoesNothingWithoutACapsuleOnTheFocusedMonitor_data() {
        return [
            { tag: "a normal bar", monitor: "Left" },
            { tag: "a hidden bar", monitor: "Hidden" },
            { tag: "a capsule hidden for fullscreen", monitor: "Fullscreen" },
            { tag: "no bar", monitor: "Elsewhere" }
        ];
    }

    function test_theToggleDoesNothingWithoutACapsuleOnTheFocusedMonitor(data) {
        compare(CapsuleRouting.toggledBar(capsuleBars(), data.monitor), null);
    }

    // The bars with their screens and whether a popup is inside, as
    // modules/Bar.qml lists them for a change (volume, brightness, Caps Lock,
    // audio output, bar profile or keep-awake).
    function changeBars() {
        return [
            { window: "left window", monitor: "Left", screen: "left screen", visible: true,
                capsule: false, popupInside: false },
            { window: "middle window", monitor: "Middle", screen: "middle screen", visible: true,
                capsule: true, popupInside: false },
            { window: "busy window", monitor: "Busy", screen: "busy screen", visible: true,
                capsule: true, popupInside: true },
            { window: "hidden window", monitor: "Hidden", screen: "hidden screen", visible: false,
                capsule: true, popupInside: false },
            { window: "fullscreen window", monitor: "Fullscreen", screen: "fullscreen screen",
                visible: true, capsule: true, popupInside: false, capsuleHidden: true }
        ];
    }

    // While the focused monitor's capsule is hidden for a fullscreen window,
    // the OSD shows the change on that monitor's screen instead.
    function test_aChangeShowsInTheOsdWhileTheCapsuleIsHiddenForFullscreen() {
        compare(CapsuleRouting.changeTarget(changeBars(), "Fullscreen"), { osd: "fullscreen screen" });
    }

    // A change on a focused monitor with a capsule expands that capsule; the
    // OSD doesn't show.
    function test_aChangeExpandsTheFocusedMonitorsCapsule() {
        compare(CapsuleRouting.changeTarget(changeBars(), "Middle"), { capsule: "middle window" });
    }

    // With a popup inside the focused monitor's capsule, a change shows
    // nowhere: neither the capsule nor the OSD.
    function test_aChangeIsIgnoredWhileAPopupIsInsideTheCapsule() {
        compare(CapsuleRouting.changeTarget(changeBars(), "Busy"), {});
    }

    // Without a capsule shown on the focused monitor, the OSD shows the change
    // on that monitor's screen; on the first screen (null) when no bar knows
    // the focused monitor.
    function test_otherwiseTheOsdShowsItOnTheFocusedScreen_data() {
        return [
            { tag: "a normal bar", monitor: "Left", target: { osd: "left screen" } },
            { tag: "a hidden capsule", monitor: "Hidden", target: { osd: "hidden screen" } },
            { tag: "no bar", monitor: "Elsewhere", target: { osd: null } }
        ];
    }

    function test_otherwiseTheOsdShowsItOnTheFocusedScreen(data) {
        compare(CapsuleRouting.changeTarget(changeBars(), data.monitor), data.target);
    }
}
