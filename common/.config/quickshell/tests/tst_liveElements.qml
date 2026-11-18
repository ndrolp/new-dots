import QtQuick
import QtTest
import "../components/bar/LiveElements.js" as LiveElements
import "../config/BarProfileModel.js" as BarProfileModel

// A capsule's live elements: which ones it draws beside its workspace pills
// and on which side, when each has something to show and how large it is.
TestCase {
    name: "LiveElements"

    // Collapsed places with `values` over the default ones.
    function places(values) {
        return Object.assign(BarProfileModel.completeCapsulePlaces(undefined), values);
    }

    function element(id, values) {
        return Object.assign({ id: id, enabled: true }, values);
    }

    function barElements() {
        return {
            left: [element("arch"), element("systemMonitor")],
            center: [element("workspaces")],
            right: [element("notifications", { options: { badgeVisible: false } }),
                element("battery"), element("clock", { joinPrevious: true })]
        };
    }

    // On a capsule, media sits left of the workspace pills and the recording
    // indicator right of them, while the profile enables them.
    function test_mediaSitsLeftOfThePillsAndRecordingRight() {
        compare(LiveElements.liveElements({ barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements }),
            { left: ["media"], right: ["recording"] });
    }

    // A live element whose place is Shown is drawn in the row, not beside
    // the pills.
    function test_aLiveElementShownInTheRowIsNotBesideThePills() {
        compare(LiveElements.liveElements({ barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements, capsulePlaces: places({ media: "shown" }) }),
            { left: [], right: ["recording"] });
    }

    // A hidden one isn't beside the pills either.
    function test_aHiddenLiveElementIsNotBesideThePills() {
        compare(LiveElements.liveElements({ barStyle: "capsule",
            barElements: BarProfileModel.defaultProfile.barElements,
            capsulePlaces: places({ recording: "hidden" }) }),
            { left: ["media"], right: [] });
    }

    // Live right puts media right of the pills, after the recording
    // indicator: several on one side follow the profile's order.
    function test_liveElementsOnOneSideFollowTheProfilesOrder() {
        const elements = barElements();
        elements.left.unshift(element("media"));
        elements.right.push(element("recording"));

        compare(LiveElements.liveElements({ barStyle: "capsule", barElements: elements,
            capsulePlaces: places({ media: "liveRight" }) }), { left: [], right: ["media", "recording"] });
    }

    // A live element the profile disables isn't beside the pills either.
    function test_aDisabledLiveElementIsNotBesideThePills() {
        const elements = barElements();
        elements.right.push(element("recording", { enabled: false }), element("media"));

        compare(LiveElements.liveElements({ barStyle: "capsule", barElements: elements }),
            { left: ["media"], right: [] });
    }

    // Live elements are a capsule's: any other bar style has none.
    function test_onlyACapsuleHasLiveElements_data() {
        return [
            { tag: "opaque", barStyle: "opaque" },
            { tag: "transparent", barStyle: "transparent" },
            { tag: "docked", barStyle: "docked" }
        ];
    }

    function test_onlyACapsuleHasLiveElements(data) {
        compare(LiveElements.liveElements({ barStyle: data.barStyle,
            barElements: BarProfileModel.defaultProfile.barElements }), { left: [], right: [] });
    }

    // Media has something to show on a bar while any player exists, but on a
    // capsule only while a track plays: a paused player leaves it.
    function test_mediaShowsOnACapsuleOnlyWhileATrackPlays_data() {
        const playing = { isPlaying: true };
        const paused = { isPlaying: false };
        return [
            { tag: "capsule, playing", barStyle: "capsule", player: playing, shown: true },
            { tag: "capsule, paused", barStyle: "capsule", player: paused, shown: false },
            { tag: "capsule, no player", barStyle: "capsule", player: null, shown: false },
            { tag: "opaque, playing", barStyle: "opaque", player: playing, shown: true },
            { tag: "opaque, paused", barStyle: "opaque", player: paused, shown: true },
            { tag: "docked, no player", barStyle: "docked", player: null, shown: false }
        ];
    }

    function test_mediaShowsOnACapsuleOnlyWhileATrackPlays(data) {
        compare(LiveElements.hasMedia({ barStyle: data.barStyle }, data.player), data.shown);
    }

    // Expanded, the capsule shows media as the bar does: while any player
    // exists, playing or not.
    function test_anExpandedCapsuleShowsMediaWhileAnyPlayerExists_data() {
        return [
            { tag: "playing", player: { isPlaying: true }, shown: true },
            { tag: "paused", player: { isPlaying: false }, shown: true },
            { tag: "no player", player: null, shown: false }
        ];
    }

    function test_anExpandedCapsuleShowsMediaWhileAnyPlayerExists(data) {
        compare(LiveElements.hasMedia({ barStyle: "capsule" }, data.player, true), data.shown);
    }

    // Keep-awake shows while off too, but as a live element a collapsed
    // capsule shows it only while it is on; expanded, it shows as on a bar.
    function test_aLiveKeepAwakeShowsCollapsedOnlyWhileOn_data() {
        const live = { keepAwake: "liveRight" };
        return [
            { tag: "live, on", barStyle: "capsule", places: live, on: true, shown: true },
            { tag: "live, off", barStyle: "capsule", places: live, on: false, shown: false },
            { tag: "live, off, expanded", barStyle: "capsule", places: live, on: false, expanded: true, shown: true },
            { tag: "live left, off", barStyle: "capsule", places: { keepAwake: "liveLeft" }, on: false, shown: false },
            { tag: "shown in the row, off", barStyle: "capsule", places: { keepAwake: "shown" }, on: false, shown: true },
            { tag: "hidden, off, expanded", barStyle: "capsule", places: { keepAwake: "hidden" }, on: false, expanded: true, shown: true },
            { tag: "opaque, off", barStyle: "opaque", places: live, on: false, shown: true }
        ];
    }

    function test_aLiveKeepAwakeShowsCollapsedOnlyWhileOn(data) {
        const elements = barElements();
        elements.right.push(element("keepAwake"));
        const bar = { barStyle: data.barStyle, barElements: elements, capsulePlaces: places(data.places) };

        compare(LiveElements.hasKeepAwake(LiveElements.liveElements(bar), data.on, data.expanded === true),
            data.shown);
    }

    // A capsule profile with the given text and icon sizes; its bar elements
    // are 20 + 3 * 2 = 26 px thick.
    function sizedProfile(textSize, iconSize) {
        return { barStyle: "capsule", barHeight: 34, elementVerticalPadding: 4,
            workspaceButtonSize: 20, pillVerticalPadding: 3, textSize: textSize, iconSize: iconSize };
    }

    // A live element beside the pills is drawn at 80% of the profile's text
    // and icon sizes, in a pill 80% as thick, rounded to whole pixels.
    function test_aLiveElementIsDrawnAtEightyPercent_data() {
        return [
            { tag: "balanced", profile: sizedProfile(14, 14), sizes: { textSize: 11, iconSize: 11, thickness: 21 } },
            { tag: "compact", profile: sizedProfile(13, 13), sizes: { textSize: 10, iconSize: 10, thickness: 21 } },
            { tag: "spacious", profile: sizedProfile(15, 15), sizes: { textSize: 12, iconSize: 12, thickness: 21 } },
            { tag: "large icons", profile: sizedProfile(14, 20), sizes: { textSize: 11, iconSize: 16, thickness: 21 } }
        ];
    }

    function test_aLiveElementIsDrawnAtEightyPercent(data) {
        compare(LiveElements.elementSizes(data.profile, true), data.sizes);
    }

    // So applying a density preset resizes live elements in proportion.
    function test_aDensityPresetResizesLiveElements() {
        const profile = Object.assign(sizedProfile(14, 14), BarProfileModel.densityPresetChanges("spacious"));

        compare(LiveElements.elementSizes(profile, true), { textSize: 12, iconSize: 12, thickness: 24 });
    }

    // Any other bar element, and every one on another bar style, keeps the
    // profile's sizes.
    function test_otherElementsKeepTheProfilesSizes() {
        compare(LiveElements.elementSizes(sizedProfile(14, 16), false),
            { textSize: 14, iconSize: 16, thickness: 26 });
    }
}
