import QtQuick
import QtTest
import "../components/bar/BarElementItems.js" as BarElementItems
import "../components/bar/BarLayout.js" as BarLayout
import "../config/BarProfileModel.js" as BarProfileModel

// The capsule is its bar elements' only background: inside it no element
// draws a pill of its own, nor an outline round one, whatever the profile's
// transparent pills and element border say. Every other bar style keeps
// drawing them as before.
TestCase {
    name: "CapsuleBackground"

    function profile(values) {
        return Object.assign({
            barStyle: "capsule",
            pillsTransparent: false,
            elementBorder: true,
            workspaceButtonSize: 20,
            barElements: { left: [], center: [{ id: "network" }, { id: "clock" }], right: [] }
        }, values);
    }

    function test_whetherAnElementDrawsAPill_data() {
        return [
            { tag: "opaque", style: "opaque", transparent: false, drawn: true },
            { tag: "opaque, transparent pills", style: "opaque", transparent: true, drawn: false },
            { tag: "transparent", style: "transparent", transparent: false, drawn: true },
            { tag: "docked", style: "docked", transparent: false, drawn: false },
            { tag: "capsule", style: "capsule", transparent: false, drawn: false },
            { tag: "capsule, transparent pills", style: "capsule", transparent: true, drawn: false }
        ];
    }

    function test_whetherAnElementDrawsAPill(data) {
        compare(BarProfileModel.elementPillsDrawn(profile({
            barStyle: data.style, pillsTransparent: data.transparent
        })), data.drawn);
    }

    function test_whetherAnElementIsOutlined_data() {
        return [
            { tag: "opaque", style: "opaque", border: true, drawn: true },
            { tag: "opaque, no element border", style: "opaque", border: false, drawn: false },
            { tag: "transparent", style: "transparent", border: true, drawn: true },
            { tag: "docked", style: "docked", border: true, drawn: true },
            { tag: "capsule", style: "capsule", border: true, drawn: false }
        ];
    }

    function test_whetherAnElementIsOutlined(data) {
        compare(BarProfileModel.elementBorderDrawn(profile({
            barStyle: data.style, elementBorder: data.border
        })), data.drawn);
    }

    // With no pill of its own, an icon-only element is as long as its glyph
    // and its padding, like any other, instead of a square pill.
    function test_anIconElementInACapsuleIsNotASquarePill() {
        compare(BarElementItems.drawsOwnPill("network", profile(), () => true), false);
        compare(BarElementItems.elementLength("network", 17.5, profile(), () => true),
            17.5 + BarElementItems.elementPadding * 2);
    }

    // The bar as BarLayout measures it, with how its groups look.
    function layoutBar(values) {
        return Object.assign({ barPosition: "top", width: 1000, height: 40, endPadding: 0 },
            BarLayout.groupLook(profile(Object.assign({
                spacing: 4, groupHorizontalPadding: 6, groupVerticalPadding: 2
            }, values))));
    }

    readonly property var lengths: ({ tray: 20, arch: 30, clock: 50, battery: 10 })

    // In the capsule's row a group draws no background: it is told apart by
    // a gap twice the spacing between it and what is beside it, while lone
    // elements keep the spacing between them.
    function test_aGroupInACapsuleIsSetApartByAWiderGap() {
        const zone = BarLayout.zone(layoutBar(), [["tray"], ["arch", "clock"], ["battery"], ["tray2"]],
            element => lengths[element] || 10);

        compare(zone.positions, {
            tray: { start: 0, grouped: false },
            arch: { start: 28, grouped: true },
            clock: { start: 62, grouped: true },
            battery: { start: 120, grouped: false },
            tray2: { start: 134, grouped: false }
        });
        compare(zone.backgrounds, []);
        compare(zone.length, 144);
    }

    function test_twoGroupsInACapsuleAreOneWiderGapApart() {
        const zone = BarLayout.zone(layoutBar(), [["arch", "clock"], ["tray", "battery"]],
            element => lengths[element]);

        compare(zone.positions.tray.start, 30 + 4 + 50 + 8);
    }

    // Any other bar style keeps each group's shared background, its padding
    // and the plain spacing between groups.
    function test_aGroupOnAnyOtherStyleKeepsItsBackground_data() {
        return ["opaque", "transparent", "docked"].map(style => ({ tag: style, style: style }));
    }

    function test_aGroupOnAnyOtherStyleKeepsItsBackground(data) {
        const bar = layoutBar({ barStyle: data.style });
        const zone = BarLayout.zone(bar, [["tray"], ["arch", "clock"], ["battery"]],
            element => lengths[element]);

        compare(zone.positions, {
            tray: { start: 0, grouped: false },
            arch: { start: 30, grouped: true },
            clock: { start: 64, grouped: true },
            battery: { start: 124, grouped: false }
        });
        compare(zone.backgrounds, [{ start: 24, length: 96 }]);
        compare(bar.groupInset, 2);
    }

    function test_anIconElementOnATransparentBarStaysASquarePill() {
        const transparentBar = profile({ barStyle: "transparent" });

        compare(BarElementItems.drawsOwnPill("network", transparentBar, () => true), true);
        compare(BarElementItems.elementLength("network", 17.5, transparentBar, () => true), 20);
    }
}
