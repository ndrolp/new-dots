import QtQuick
import QtTest
import "../components/panels/NotificationPlacement.js" as NotificationPlacement

// Where the toasts sit in the area their monitor leaves free: the compositor
// keeps them clear of the bar, so the anchors say which side and the margins
// are plain gaps from that area.
TestCase {
    name: "NotificationPlacement"

    readonly property var profile: ({ spacing: 8, horizontalPadding: 12 })

    function test_aCornerAnchorsToItsTwoSides() {
        compare(NotificationPlacement.place("top-left", profile).anchors,
            { top: true, right: false, bottom: false, left: true });
        compare(NotificationPlacement.place("top-right", profile).anchors,
            { top: true, right: true, bottom: false, left: false });
        compare(NotificationPlacement.place("bottom-left", profile).anchors,
            { top: false, right: false, bottom: true, left: true });
        compare(NotificationPlacement.place("bottom-right", profile).anchors,
            { top: false, right: true, bottom: true, left: false });
    }

    function test_theCenterAnchorsToNeitherSideSoItCentersInTheFreeArea() {
        compare(NotificationPlacement.place("top-center", profile).anchors,
            { top: true, right: false, bottom: false, left: false });
        compare(NotificationPlacement.place("bottom-center", profile).anchors,
            { top: false, right: false, bottom: true, left: false });
    }

    function test_theMarginsAreGapsOnTheSidesItIsAnchoredTo() {
        compare(NotificationPlacement.place("top-left", profile).margins,
            { top: 8, right: 0, bottom: 0, left: 12 });
        compare(NotificationPlacement.place("bottom-right", profile).margins,
            { top: 0, right: 12, bottom: 8, left: 0 });
        compare(NotificationPlacement.place("bottom-center", profile).margins,
            { top: 0, right: 0, bottom: 8, left: 0 });
    }

    function test_theBarsSizeDoesNotMoveThem() {
        const withBar = { spacing: 8, horizontalPadding: 12, barHeight: 60,
            transparentBarTopMargin: 20, barPosition: "bottom" };

        compare(NotificationPlacement.place("top-left", withBar),
            NotificationPlacement.place("top-left", profile));
    }
}
