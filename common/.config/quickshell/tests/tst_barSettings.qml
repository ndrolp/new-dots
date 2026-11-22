import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// The Bar section as one scroll of cards: Profile, Style, Bar, Groups,
// Elements and, on a capsule profile, Capsule, each holding its settings in
// reading order.
TestCase {
    name: "BarSettings"
    width: 900
    height: 2400
    visible: true
    when: windowShown

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    // A fake appearance with what every card of the section reads; it
    // records what is saved.
    Component {
        id: sectionArea

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 760

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(false)
                property var barProfiles: ({ "work": {} })
                property string editingBarProfile: "work"
                property bool barProfileModified: false
                property string barPosition: "top"
                property string barStyle: "opaque"
                property int iconSize: 13
                property int barHeight: 32
                property int barOpacity: 90
                property int horizontalPadding: 12
                property int pillVerticalPadding: 4
                property int workspacePadding: 4
                property int elementVerticalPadding: 4
                property int transparentBarTopMargin: 8
                property int capsuleVerticalPadding: 6
                property int groupRadius: 16
                property int spacing: 8
                property int groupHorizontalPadding: 8
                property int groupVerticalPadding: 0
                property bool barBorder: false
                property bool elementBorder: false
                property bool groupBorder: false
                property bool pillsTransparent: false
                property bool capsuleNotifications: false
                property string matchingDensityPreset: "balanced"
                property var capsulePlaces: ({})
                property var barElements: ({ left: [{ id: "clock", enabled: true }], center: [], right: [] })
                property var saved: []

                function setBarSetting(name, value) {
                    saved = saved.concat([[name, value]]);
                }

                function applyDensityPreset(preset) {}
                function barElementOption(element, option) { return false; }
                function duplicateNameError(name) { return ""; }
                function renameNameError(name) { return ""; }
                function deleteBarProfileRejection(profile, displaySettings) { return ""; }
                function suggestedDuplicateName() { return "work 2"; }
            }

            Panels.BarSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make(style) {
        const built = createTemporaryObject(sectionArea, this);
        built.appearance.barStyle = style || "opaque";
        // The cards shown or hidden for the style are laid out on the next frame.
        waitForRendering(built.section);
        return { appearance: built.appearance, item: built.section };
    }

    function yIn(item, root) {
        return item.mapToItem(root, 0, 0).y;
    }

    function shownCards(section) {
        return all(section, child => child instanceof Panels.SettingsCard && child.visible)
            .sort((a, b) => yIn(a, section) - yIn(b, section));
    }

    function card(section, title) {
        return shownCards(section).find(found => found.title === title) || null;
    }

    // The labelled settings shown in a card, top to bottom and left to right.
    function settingsIn(card) {
        return all(card, child => child.visible && typeof child.label === "string" && child.label !== ""
            && (child.small !== undefined || child.switchItem !== undefined))
            .map(setting => ({ label: setting.label, at: setting.mapToItem(card, 0, 0) }))
            .sort((a, b) => a.at.y - b.at.y || a.at.x - b.at.x)
            .map(setting => setting.label);
    }

    function test_theSectionIsSixCardsInOrderOnACapsule() {
        const built = make("capsule");

        compare(shownCards(built.item).map(found => found.title),
            ["Profile", "Style", "Bar", "Groups", "Elements", "Capsule"]);
    }

    function test_theCapsuleCardShowsOnlyForACapsule_data() {
        return [
            { tag: "opaque", style: "opaque" },
            { tag: "transparent", style: "transparent" },
            { tag: "docked", style: "docked" }
        ];
    }

    function test_theCapsuleCardShowsOnlyForACapsule(data) {
        const built = make(data.style);

        compare(shownCards(built.item).map(found => found.title),
            ["Profile", "Style", "Bar", "Groups", "Elements"]);
    }

    function test_eachCardHoldsItsSettingsInOrder_data() {
        return [
            { tag: "Style", settings: ["Bar style", "Bar position"] },
            { tag: "Bar", settings: ["Density preset", "Bar thickness", "Bar opacity", "Corner radius",
                "Horizontal padding", "Bar border", "Edge margin"] },
            { tag: "Groups", settings: ["Group radius", "Group horizontal padding", "Group vertical padding",
                "Group border"] },
            { tag: "Elements", settings: ["Icon size", "Pill vertical padding",
                "Component spacing", "Element border", "Transparent pills"] },
            { tag: "Capsule", settings: ["Capsule vertical padding", "Notifications in the capsule"] }
        ];
    }

    function test_eachCardHoldsItsSettingsInOrder(data) {
        const built = make("capsule");
        const found = card(built.item, data.tag);

        verify(found, data.tag + " is not shown");
        compare(settingsIn(found), data.settings);
    }

    // Only the settings the bar uses on its style show; the rest are hidden.
    function test_eachBarStyleShowsOnlyTheSettingsItsBarUses_data() {
        return [
            { tag: "opaque", style: "opaque",
                bar: ["Density preset", "Bar thickness", "Bar opacity", "Corner radius", "Horizontal padding",
                    "Vertical padding", "Bar border"],
                elements: ["Icon size", "Component spacing", "Element border", "Transparent pills"] },
            { tag: "transparent", style: "transparent",
                bar: ["Density preset", "Bar thickness", "Bar opacity", "Corner radius", "Horizontal padding",
                    "Edge margin"],
                elements: ["Icon size", "Pill vertical padding", "Component spacing", "Element border",
                    "Transparent pills"] },
            { tag: "docked", style: "docked",
                bar: ["Density preset", "Bar thickness", "Bar opacity", "Corner radius", "Horizontal padding",
                    "Bar border"],
                elements: ["Icon size", "Pill vertical padding", "Component spacing", "Element border"] }
        ];
    }

    function test_eachBarStyleShowsOnlyTheSettingsItsBarUses(data) {
        const built = make(data.style);

        compare(settingsIn(card(built.item, "Bar")), data.bar);
        compare(settingsIn(card(built.item, "Elements")), data.elements);
    }

    // Switching bar style shows and hides settings straight away.
    function test_switchingBarStyleUpdatesTheShownSettingsAtOnce() {
        const built = make("opaque");

        built.appearance.barStyle = "capsule";
        waitForRendering(built.item);
        compare(settingsIn(card(built.item, "Bar")), ["Density preset", "Bar thickness", "Bar opacity",
            "Corner radius", "Horizontal padding", "Bar border", "Edge margin"]);
        verify(card(built.item, "Capsule"));

        built.appearance.barStyle = "opaque";
        waitForRendering(built.item);
        compare(settingsIn(card(built.item, "Bar")), ["Density preset", "Bar thickness", "Bar opacity",
            "Corner radius", "Horizontal padding", "Vertical padding", "Bar border"]);
        compare(card(built.item, "Capsule"), null);
    }

    // The element list follows the Elements card's settings, inside it.
    function test_theElementListSitsInTheElementsCardAfterItsSettings() {
        const built = make("capsule");
        const elements = card(built.item, "Elements");
        const row = all(elements, child => child.elementLabel === "Clock")[0];
        const lastSetting = all(elements, child => child.label === "Transparent pills"
            && child.switchItem !== undefined)[0];

        verify(row, "the element list is outside the Elements card");
        verify(yIn(row, elements) > yIn(lastSetting, elements));
    }

    // Edge margin is the transparent bar margin of before: same key, same value.
    function test_edgeMarginKeepsTheStoredMargin() {
        const built = make("transparent");
        const margin = all(card(built.item, "Bar"), child => child.label === "Edge margin"
            && child.field !== undefined)[0];

        compare(margin.value, 8);
        margin.edited(12);
        compare(built.appearance.saved, [["transparentBarTopMargin", 12]]);
    }

    function test_settingsSaveUnderTheirKeys() {
        const built = make("capsule");
        const capsule = card(built.item, "Capsule");

        all(capsule, child => child.label === "Notifications in the capsule"
            && child.switchItem !== undefined)[0].toggled();
        all(card(built.item, "Groups"), child => child.label === "Group border"
            && child.switchItem !== undefined)[0].toggled();
        all(capsule, child => child.label === "Capsule vertical padding"
            && child.field !== undefined)[0].edited(9);

        compare(built.appearance.saved, [["capsuleNotifications", true], ["groupBorder", true],
            ["capsuleVerticalPadding", 9]]);
    }
}
