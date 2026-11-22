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

    // Hovering the capsule expands it, but not over a live element: there a
    // click opens the element's popup inside the capsule straight from rest,
    // with no expanded row first.
    function test_hoveringALiveElementDoesNotExpandTheCapsule_data() {
        return [
            { tag: "away", pointer: { overCapsule: false, overLiveElement: false }, expands: false },
            { tag: "over the capsule", pointer: { overCapsule: true, overLiveElement: false }, expands: true },
            { tag: "over a live element", pointer: { overCapsule: true, overLiveElement: true }, expands: false },
            { tag: "nothing known", pointer: undefined, expands: false }
        ];
    }

    function test_hoveringALiveElementDoesNotExpandTheCapsule(data) {
        compare(CapsuleRouting.hoverExpands(data.pointer), data.expands);
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

    // The bars as modules/Bar.qml lists them for a new notification: whether
    // their profile turns notifications in the capsule on.
    function notificationBars() {
        return [
            { window: "left window", monitor: "Left", visible: true, capsule: false,
                capsuleNotifications: true },
            { window: "middle window", monitor: "Middle", visible: true, capsule: true,
                capsuleNotifications: true },
            { window: "off window", monitor: "Off", visible: true, capsule: true,
                capsuleNotifications: false },
            { window: "busy window", monitor: "Busy", visible: true, capsule: true,
                capsuleNotifications: true, popupInside: true },
            { window: "hidden window", monitor: "Hidden", visible: false, capsule: true,
                capsuleNotifications: true },
            { window: "fullscreen window", monitor: "Fullscreen", visible: true, capsule: true,
                capsuleNotifications: true, capsuleHidden: true }
        ];
    }

    // With notifications in the capsule on, a new notification shows in the
    // focused monitor's capsule.
    function test_aNotificationShowsInTheFocusedMonitorsCapsule() {
        compare(CapsuleRouting.notificationTarget(notificationBars(), "Middle"), "middle window");
    }

    // Otherwise it is a toast (null): with the setting off, on another bar
    // style, with a popup or panel inside the capsule, with the capsule
    // hidden for a fullscreen window, or without a bar on the focused monitor.
    function test_otherwiseANotificationIsAToast_data() {
        return [
            { tag: "the setting off", monitor: "Off" },
            { tag: "a normal bar", monitor: "Left" },
            { tag: "a popup inside", monitor: "Busy" },
            { tag: "a hidden bar", monitor: "Hidden" },
            { tag: "a capsule hidden for fullscreen", monitor: "Fullscreen" },
            { tag: "no bar", monitor: "Elsewhere" }
        ];
    }

    function test_otherwiseANotificationIsAToast(data) {
        compare(CapsuleRouting.notificationTarget(notificationBars(), data.monitor), null);
    }

    // Do Not Disturb, and a kept notification sent again after a reload, keep
    // a notification out of the capsule (and quiet): it goes to the history
    // only, through the toasts, which stay hidden.
    function test_aQuietNotificationNeverShowsInTheCapsule_data() {
        return [
            { tag: "do not disturb", arrival: { doNotDisturb: true, lastGeneration: false } },
            { tag: "sent again after a reload", arrival: { doNotDisturb: false, lastGeneration: true } }
        ];
    }

    function test_aQuietNotificationNeverShowsInTheCapsule(data) {
        compare(CapsuleRouting.notificationTarget(notificationBars(), "Middle", data.arrival), null);
    }

    function test_aNotificationIsAnnouncedUnlessQuiet_data() {
        return [
            { tag: "a new one", arrival: { doNotDisturb: false, lastGeneration: false }, announced: true },
            { tag: "do not disturb", arrival: { doNotDisturb: true, lastGeneration: false }, announced: false },
            { tag: "sent again after a reload", arrival: { doNotDisturb: false, lastGeneration: true },
                announced: false }
        ];
    }

    function test_aNotificationIsAnnouncedUnlessQuiet(data) {
        compare(CapsuleRouting.announced(data.arrival), data.announced);
    }

    // Whether a bar's capsule can hold notifications, which a bar window
    // asks of itself to hand those it holds back as toasts once it can't:
    // the same answer notificationTarget gives for the focused monitor.
    function test_aCapsuleHoldsNotificationsWhereTheyWouldShow_data() {
        return notificationBars().map(bar => ({ tag: bar.monitor, bar: bar,
            holds: bar.monitor === "Middle" }));
    }

    function test_aCapsuleHoldsNotificationsWhereTheyWouldShow(data) {
        compare(CapsuleRouting.holdsNotifications(data.bar), data.holds);
    }

    // A capsule is available, to SUPER+I, a change and a new notification,
    // while it is shown and not hidden for a fullscreen window; a popup inside
    // doesn't change that.
    function test_aCapsuleIsAvailableWhileShownAndNotHidden_data() {
        return notificationBars().map(bar => ({ tag: bar.monitor, bar: bar,
            available: ["Middle", "Off", "Busy"].indexOf(bar.monitor) !== -1 }))
            .concat([{ tag: "no bar", bar: undefined, available: false }]);
    }

    function test_aCapsuleIsAvailableWhileShownAndNotHidden(data) {
        compare(CapsuleRouting.capsuleAvailable(data.bar), data.available);
    }

    // Which view a capsule's row shows, so it crossfades between them: a
    // change over everything, then expanded, else at rest.
    function test_aCapsulesRowShowsOneView_data() {
        return [
            { tag: "at rest", row: { change: false, expanded: false }, view: "rest" },
            { tag: "expanded", row: { change: false, expanded: true }, view: "expanded" },
            { tag: "a change", row: { change: true, expanded: false }, view: "change" },
            { tag: "a change while expanded", row: { change: true, expanded: true }, view: "change" }
        ];
    }

    function test_aCapsulesRowShowsOneView(data) {
        compare(CapsuleRouting.rowView(data.row), data.view);
    }
}
