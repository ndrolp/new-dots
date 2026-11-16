import QtQuick
import QtTest
import "../components/bar/BarPlacement.js" as BarPlacement
import "../components/panels/PopupPlacement.js" as PopupPlacement

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
            spacing: 4,
            barStyle: "opaque"
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
            { tag: "floating", values: { barStyle: "transparent" }, thickness: 36 },
            { tag: "docked", values: { barStyle: "docked" }, thickness: 30 },
            // A capsule also reserves room past its row for its workspace pills:
            // 4 deep and the profile's spacing past them.
            { tag: "capsule", values: { barStyle: "capsule" }, thickness: 44 },
            { tag: "floating at the bottom", values: { barStyle: "transparent", barPosition: "bottom" },
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
        compare(BarPlacement.contentMargins(bar({ barStyle: "transparent", barPosition: data.tag })),
            data.margins);
    }

    function test_anOpaqueBarHasNoMargin() {
        compare(BarPlacement.contentMargins(bar({ barPosition: "bottom" })),
            { top: 0, right: 12, bottom: 0, left: 12 });
    }

    // A docked bar's zones reach the screen's sides and pad their own contents.
    function test_aDockedBarHasNoMarginOrPadding() {
        compare(BarPlacement.contentMargins(bar({ barPosition: "bottom", barStyle: "docked" })), { top: 0, right: 0, bottom: 0, left: 0 });
    }

    // Only the capsule is tied to a Bar position (top or bottom): the other
    // styles' twelve and the capsule's two are a working bar with the room it
    // reserves, its margins and how its popups open.
    function test_everyBarStyleWorksOnEveryBarPosition_data() {
        const opaque = { barStyle: "opaque" };
        const floating = { barStyle: "transparent" };
        const docked = { barStyle: "docked" };
        // A capsule only sits at the top or the bottom.
        const capsule = { barStyle: "capsule" };

        return [
            { tag: "opaque top", style: opaque, barPosition: "top", thickness: 30, attached: true,
                margins: { top: 0, right: 12, bottom: 0, left: 12 } },
            { tag: "opaque bottom", style: opaque, barPosition: "bottom", thickness: 30, attached: true,
                margins: { top: 0, right: 12, bottom: 0, left: 12 } },
            { tag: "opaque left", style: opaque, barPosition: "left", thickness: 30, attached: true,
                margins: { top: 12, right: 0, bottom: 12, left: 0 } },
            { tag: "opaque right", style: opaque, barPosition: "right", thickness: 30, attached: true,
                margins: { top: 12, right: 0, bottom: 12, left: 0 } },
            { tag: "floating top", style: floating, barPosition: "top", thickness: 36, attached: false,
                margins: { top: 6, right: 12, bottom: 0, left: 12 } },
            { tag: "floating bottom", style: floating, barPosition: "bottom", thickness: 36, attached: false,
                margins: { top: 0, right: 12, bottom: 6, left: 12 } },
            { tag: "floating left", style: floating, barPosition: "left", thickness: 36, attached: false,
                margins: { top: 12, right: 0, bottom: 12, left: 6 } },
            { tag: "floating right", style: floating, barPosition: "right", thickness: 36, attached: false,
                margins: { top: 12, right: 6, bottom: 12, left: 0 } },
            { tag: "docked top", style: docked, barPosition: "top", thickness: 30, attached: true,
                margins: { top: 0, right: 0, bottom: 0, left: 0 } },
            { tag: "docked bottom", style: docked, barPosition: "bottom", thickness: 30, attached: true,
                margins: { top: 0, right: 0, bottom: 0, left: 0 } },
            { tag: "docked left", style: docked, barPosition: "left", thickness: 30, attached: true,
                margins: { top: 0, right: 0, bottom: 0, left: 0 } },
            { tag: "docked right", style: docked, barPosition: "right", thickness: 30, attached: true,
                margins: { top: 0, right: 0, bottom: 0, left: 0 } },
            { tag: "capsule top", style: capsule, barPosition: "top", thickness: 44, attached: false,
                margins: { top: 6, right: 12, bottom: 0, left: 12 } },
            { tag: "capsule bottom", style: capsule, barPosition: "bottom", thickness: 44, attached: false,
                margins: { top: 0, right: 12, bottom: 6, left: 12 } }
        ];
    }

    function test_everyBarStyleWorksOnEveryBarPosition(data) {
        const styled = bar(Object.assign({ barPosition: data.barPosition }, data.style));

        compare(BarPlacement.thickness(styled), data.thickness);
        compare(BarPlacement.contentMargins(styled), data.margins);
        compare(PopupPlacement.attached(styled), data.attached);
    }

    function test_anOpaqueBarsBorderRunsAlongTheEdgeFacingTheDesktop_data() {
        return [
            { tag: "top", window: { width: 1000, height: 30 },
                pieces: [{ x: 0, y: 29, width: 1000, height: 1 }] },
            { tag: "bottom", window: { width: 1000, height: 30 },
                pieces: [{ x: 0, y: 0, width: 1000, height: 1 }] },
            { tag: "left", window: { width: 30, height: 800 },
                pieces: [{ x: 29, y: 0, width: 1, height: 800 }] },
            { tag: "right", window: { width: 30, height: 800 },
                pieces: [{ x: 0, y: 0, width: 1, height: 800 }] }
        ];
    }

    function test_anOpaqueBarsBorderRunsAlongTheEdgeFacingTheDesktop(data) {
        compare(BarPlacement.edgeBorder(data.tag, data.window, null), data.pieces);
    }

    function test_anOpaqueBarsBorderBreaksWhereAPopupHangsFromIt() {
        compare(BarPlacement.edgeBorder("top", { width: 1000, height: 30 }, { start: 100, end: 300 }), [
            { x: 0, y: 29, width: 100, height: 1 },
            { x: 300, y: 29, width: 700, height: 1 }
        ]);
        compare(BarPlacement.edgeBorder("left", { width: 30, height: 800 }, { start: 0, end: 300 }), [
            { x: 29, y: 300, width: 1, height: 500 }
        ]);
    }

    // The bar content sits in the bar window inside its margins, as deep as
    // the bar's thickness leaves it, against the bar's screen edge: a
    // capsule's window grown for a popup inside leaves its content where it
    // was, whatever size the window is.
    function test_theBarContentSitsAgainstItsScreenEdge_data() {
        return [
            { tag: "opaque top", values: {}, window: { width: 1920, height: 30 },
                area: { x: 12, y: 0, width: 1896, height: 30 } },
            { tag: "capsule top, grown", values: { barStyle: "capsule" }, window: { width: 1920, height: 400 },
                area: { x: 12, y: 6, width: 1896, height: 30 } },
            { tag: "capsule bottom, grown", values: { barStyle: "capsule", barPosition: "bottom" },
                window: { width: 1920, height: 400 }, area: { x: 12, y: 364, width: 1896, height: 30 } },
            { tag: "opaque left", values: { barPosition: "left" }, window: { width: 30, height: 1080 },
                area: { x: 0, y: 12, width: 30, height: 1056 } },
            { tag: "transparent right", values: { barStyle: "transparent", barPosition: "right" },
                window: { width: 36, height: 1080 }, area: { x: 0, y: 12, width: 30, height: 1056 } }
        ];
    }

    function test_aCapsulesWorkspacePillsReachPastItsRow_data() {
        return [
            { tag: "capsule", values: { barStyle: "capsule" }, strip: 8 },
            { tag: "capsule, wider spacing", values: { barStyle: "capsule", spacing: 6 }, strip: 10 },
            { tag: "opaque", values: {}, strip: 0 },
            { tag: "transparent", values: { barStyle: "transparent" }, strip: 0 },
            { tag: "docked", values: { barStyle: "docked" }, strip: 0 }
        ];
    }

    function test_aCapsulesWorkspacePillsReachPastItsRow(data) {
        compare(BarPlacement.workspaceStrip(bar(data.values)), data.strip);
    }

    function test_theBarContentSitsAgainstItsScreenEdge(data) {
        compare(BarPlacement.contentArea(bar(data.values), data.window), data.area);
    }
}
