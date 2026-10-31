import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../config" as Config
import "../config/ControlCenterTiles.js" as ControlCenterTiles

// The settings panel's frame: its title, the sidebar of sections and the
// section shown. Only the section title is bold.
TestCase {
    name: "ConfigPanel"
    width: 1000
    height: 600
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: fakeAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(false)
        property string notificationPopupLocation: "top-right"
        readonly property var controlCenterTiles: ControlCenterTiles.defaultTiles()
    }

    Component {
        id: panel

        Panels.ConfigPanel {
            appearance: fakeAppearance
            monitors: null
            wallpapers: null
            bookmarks: null
            plugins: null
            currentSection: "Notifications"
        }
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function textOf(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput))[0] || null;
    }

    function test_onlyTheSectionTitleIsBold() {
        const item = createTemporaryObject(panel, this);
        const bold = all(item, child => child.font !== undefined && child.font.bold);

        compare(bold.map(child => child.text), ["Notifications"]);
        verify(textOf(item, "Settings"));
    }

    function test_searchingForAnimationsFindsTheMotionSection() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "animation" });

        compare(item.filteredSections.map(section => section.label), ["Motion"]);
    }

    // A search that matches no section says so as a hint, like the hints in
    // the sections.
    function test_aSearchMatchingNothingSaysSoAsAHint() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "zzzz" });
        const hint = textOf(item, "No settings match this search.");

        compare(item.filteredSections.length, 0);
        compare(hint.color, theme.textMuted);
        compare(hint.font.pixelSize, 12);
        verify(hint.appearance !== undefined, "it is a settings hint");
    }

    function test_searchingForTilesFindsTheControlCenterSection() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "tiles" });

        compare(item.filteredSections.map(section => section.label), ["Control center"]);
    }

    // The pencil in the expanded control center opens the panel at its section.
    function test_openingAtTheControlCenterSectionShowsItsTiles() {
        const item = createTemporaryObject(panel, this);

        item.openSection("ControlCenter");

        compare(item.currentSection, "ControlCenter");
        verify(all(item, child => child.text === "Control center" && child.font !== undefined
            && child.font.bold)[0], "its title");
        verify(all(item, child => child.tileLabel === "Night light")[0], "its tiles");
    }
}
