import QtQuick
import QtTest
import "../components/bar/BarPlacement.js" as BarPlacement

// Where the bar sits on its screen: the edges its window is anchored to, the
// space it reserves and where its content sits in that space.
TestCase {
    name: "BarPlacement"

    function bar(values) {
        return Object.assign({
            barPosition: "top",
            barHeight: 30,
            horizontalPadding: 12,
            transparentBarTopMargin: 6,
            barTransparent: false,
            transparentBarSlanted: false
        }, values);
    }

    function test_theBarWindowHugsItsScreenEdge_data() {
        return [
            { tag: "top", anchors: { top: true, right: true, bottom: false, left: true } },
            { tag: "bottom", anchors: { top: false, right: true, bottom: true, left: true } },
            { tag: "left", anchors: { top: true, right: false, bottom: true, left: true } },
            { tag: "right", anchors: { top: true, right: true, bottom: true, left: false } }
        ];
    }

    function test_theBarWindowHugsItsScreenEdge(data) {
        compare(BarPlacement.windowAnchors(data.tag), data.anchors);
    }

    function test_theBarReservesItsThickness_data() {
        return [
            { tag: "opaque", values: {}, thickness: 30 },
            { tag: "floating", values: { barTransparent: true }, thickness: 36 },
            { tag: "docked", values: { barTransparent: true, transparentBarSlanted: true }, thickness: 30 },
            { tag: "floating at the bottom", values: { barTransparent: true, barPosition: "bottom" },
                thickness: 36 }
        ];
    }

    function test_theBarReservesItsThickness(data) {
        compare(BarPlacement.thickness(bar(data.values)), data.thickness);
    }

    // The margin keeps a floating bar clear of the screen edge it sits on; the
    // padding keeps its contents clear of the bar's two ends.
    function test_theMarginIsOnTheBarsScreenEdge_data() {
        return [
            { tag: "top", margins: { top: 6, right: 12, bottom: 0, left: 12 } },
            { tag: "bottom", margins: { top: 0, right: 12, bottom: 6, left: 12 } },
            { tag: "left", margins: { top: 12, right: 0, bottom: 12, left: 6 } },
            { tag: "right", margins: { top: 12, right: 6, bottom: 12, left: 0 } }
        ];
    }

    function test_theMarginIsOnTheBarsScreenEdge(data) {
        compare(BarPlacement.contentMargins(bar({ barTransparent: true, barPosition: data.tag })),
            data.margins);
    }

    function test_anOpaqueBarHasNoMargin() {
        compare(BarPlacement.contentMargins(bar({ barPosition: "bottom" })),
            { top: 0, right: 12, bottom: 0, left: 12 });
    }

    // A docked bar's zones reach the screen's sides and pad their own contents.
    function test_aDockedBarHasNoMarginOrPadding() {
        compare(BarPlacement.contentMargins(bar({ barPosition: "bottom", barTransparent: true,
            transparentBarSlanted: true })), { top: 0, right: 0, bottom: 0, left: 0 });
    }
}
