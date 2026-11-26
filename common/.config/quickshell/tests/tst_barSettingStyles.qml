import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel

// Which Bar section settings show for each bar style: only those the bar
// draws something with on that style.
TestCase {
    name: "BarSettingStyles"

    // Every number and switch of the Bar section, by profile key.
    readonly property var barSettings: [
        "barHeight", "barOpacity", "radius", "horizontalPadding", "elementVerticalPadding",
        "barBorder", "transparentBarTopMargin",
        "groupRadius", "groupHorizontalPadding", "groupVerticalPadding", "groupBorder",
        "iconSize", "pillVerticalPadding", "spacing", "elementBorder",
        "pillsTransparent",
        "capsuleVerticalPadding", "capsuleNotifications"
    ]

    function shownFor(style) {
        return barSettings.filter(key => BarProfileModel.barSettingShown(style, key));
    }

    function test_eachBarStyleShowsTheSettingsItsBarUses_data() {
        const shared = ["barHeight", "barOpacity", "radius", "horizontalPadding",
            "groupRadius", "groupHorizontalPadding", "groupVerticalPadding",
            "iconSize", "spacing"];
        return [
            { tag: "opaque", style: "opaque", only: ["elementVerticalPadding", "barBorder", "pillsTransparent",
                "groupBorder", "elementBorder"] },
            { tag: "transparent", style: "transparent",
                only: ["transparentBarTopMargin", "pillVerticalPadding", "pillsTransparent",
                    "groupBorder", "elementBorder"] },
            { tag: "docked", style: "docked", only: ["barBorder", "pillVerticalPadding",
                "groupBorder", "elementBorder"] },
            { tag: "capsule", style: "capsule", only: ["barBorder", "transparentBarTopMargin",
                "pillVerticalPadding", "capsuleVerticalPadding", "capsuleNotifications"] }
        ].map(row => Object.assign(row, { shown: barSettings.filter(key =>
            shared.indexOf(key) !== -1 || row.only.indexOf(key) !== -1) }));
    }

    function test_eachBarStyleShowsTheSettingsItsBarUses(data) {
        compare(shownFor(data.style), data.shown);
    }

    // The examples the spec names.
    function test_edgeMarginShowsOnlyForTransparentAndCapsule() {
        compare(BarProfileModel.barStyles.filter(style =>
            BarProfileModel.barSettingShown(style, "transparentBarTopMargin")), ["transparent", "capsule"]);
    }

    function test_barBorderShowsForEveryStyleButTransparent() {
        compare(BarProfileModel.barStyles.filter(style =>
            BarProfileModel.barSettingShown(style, "barBorder")), ["opaque", "docked", "capsule"]);
    }

    // The capsule is its elements' only background: none of them draws a
    // pill or a group background there, so nothing is see-through or outlined.
    function test_aCapsuleHidesThePillAndBorderSettings() {
        compare(BarProfileModel.barSettingsShown("capsule", [
            { propertyName: "pillsTransparent" },
            { propertyName: "elementBorder" },
            { propertyName: "groupBorder" }
        ]), []);
    }

    // A card's settings list, kept to those the style shows, in its order.
    function test_aSettingsListKeepsOnlyTheShownOnesInOrder() {
        const settings = [
            { label: "Bar border", propertyName: "barBorder" },
            { label: "Bar thickness", from: 24, to: 56, propertyName: "barHeight" },
            { label: "Edge margin", from: 0, to: 32, propertyName: "transparentBarTopMargin" }
        ];

        compare(BarProfileModel.barSettingsShown("transparent", settings).map(setting => setting.label),
            ["Bar thickness", "Edge margin"]);
        compare(BarProfileModel.barSettingsShown("opaque", settings).map(setting => setting.label),
            ["Bar border", "Bar thickness"]);
    }

    function test_theCapsuleSettingsLeaveNothingOnOtherStyles() {
        const capsuleCard = [{ propertyName: "capsuleVerticalPadding" }, { propertyName: "capsuleNotifications" }];

        compare(BarProfileModel.barSettingsShown("docked", capsuleCard), []);
        compare(BarProfileModel.barSettingsShown("capsule", capsuleCard).length, 2);
    }
}
