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
    visible: true
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

    function test_everySectionFitsInTheSidebarWithoutScrolling() {
        const item = createTemporaryObject(panel, this);
        const sections = item.sections.map(section => section.label);
        verify(sections.includes("Wallpapers"));
        for (const label of sections) {
            const row = textOf(item, label);
            const bottom = row.mapToItem(item, 0, row.height).y;
            verify(bottom <= item.height - 20, label + " ends at " + bottom + ", past the panel");
        }
    }

    // A longer list scrolls inside the panel instead of drawing past its edge.
    function test_theSidebarKeepsItsRowsInsideThePanel() {
        const item = createTemporaryObject(panel, this);
        const sidebar = all(item, child => child.objectName === "sectionSidebar")[0];
        verify(sidebar !== undefined, "the sidebar doesn't scroll");
        verify(sidebar.clip, "the sidebar draws past its edge");
        compare(sidebar.width, 180);
        verify(sidebar.mapToItem(item, 0, sidebar.height).y <= item.height - 20);
    }

    // The sidebar row of `section`.
    function sidebarRow(item, section) {
        return all(item, child => child.modelData !== undefined && child.selected !== undefined
            && child.modelData.section === section)[0];
    }

    // The accent bar on the left of a sidebar row, shown or not.
    function accentBarOf(row) {
        return all(row, child => child instanceof Rectangle && child !== row && child.width <= 4
            && Qt.colorEqual(child.color, theme.accent))[0];
    }

    // The selected section stands out three ways: a fill, an accent bar on
    // its left and accent text. The others are plain until hovered.
    function test_theSelectedSectionHasAFillAnAccentBarAndAccentText() {
        const item = createTemporaryObject(panel, this);
        const selected = sidebarRow(item, "Notifications");
        const other = sidebarRow(item, "Motion");
        const bar = accentBarOf(selected);

        tryCompare(selected, "color", theme.surfaceHover, 500);
        verify(bar, "no accent bar");
        tryCompare(bar, "opacity", 1, 500);
        compare(bar.mapToItem(selected, 0, 0).x, 0);
        verify(bar.height > 0 && bar.height < selected.height);
        compare(all(selected, child => child.text === "Notifications")[0].color, theme.accent);

        compare(other.color, Qt.rgba(0, 0, 0, 0));
        compare(accentBarOf(other).opacity, 0);
        compare(all(other, child => child.text === "Motion")[0].color, theme.text);
    }

    // A sidebar row is clicked to open its section: it shows a pointing hand.
    function test_aSidebarRowIsClicked() {
        const item = createTemporaryObject(panel, this);

        verify(sidebarRow(item, "Motion").clickable);
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

    // Each section's title and description come from its entry in the
    // sections list, next to its label, icon and keywords.
    function test_eachSectionShowsTheTitleAndDescriptionOfItsEntry() {
        const item = createTemporaryObject(panel, this);
        const displays = item.sections.find(section => section.section === "Monitors");
        compare(displays.title, "Displays");
        compare(displays.description, "Set workspace ranges and shell visibility for each monitor.");

        for (const entry of item.sections) {
            item.openSection(entry.section);
            verify(entry.description.length > 0, entry.section + " has no description");
            verify(all(item, child => child.text === entry.title && child.font !== undefined
                && child.font.bold)[0], entry.section + " shows its title");
            verify(textOf(item, entry.description), entry.section + " shows its description");
        }
    }

    // The header keeps the title on the left and search then Done on the
    // right, at the panel's margins, whatever the panel's width.
    function test_theHeaderSitsTitleLeftAndSearchAndDoneRight() {
        for (const width of [980, 760]) {
            const item = createTemporaryObject(panel, this, { width: width });
            const title = textOf(item, "Settings");
            const search = all(item, child => child.placeholderText === "Search settings")[0];
            const done = all(item, child => child.label === "Done")[0];
            const x = child => child.mapToItem(item, 0, 0).x;
            tryVerify(() => x(done) + done.width === width - 20, 1000, "Done ends at " + (x(done) + done.width));

            compare(x(title), 20);
            compare(x(done) + done.width, width - 20);
            compare(x(search) + search.width, x(done) - 16);
            compare(search.width, 244);
            verify(x(title) + title.width < x(search), "the title runs into the search");
        }
    }

    // The section's scroll area.
    function sectionScrollOf(item) {
        return all(item, child => child.objectName === "sectionScroll")[0].contentItem;
    }

    // Moving between the centered position and inside a capsule hands the
    // panel's view to the other panel: it comes up on the same section, at
    // the same scroll position, with the same search text.
    function test_aPanelPicksUpAnotherPanelsView() {
        const from = createTemporaryObject(panel, this, { height: 300 });
        from.openSection("ControlCenter");
        from.sectionQuery = "tiles";
        const scroll = sectionScrollOf(from);
        tryVerify(() => scroll.contentHeight > scroll.height + 60, 1000, "the section doesn't scroll");
        scroll.contentY = 60;

        const to = createTemporaryObject(panel, this, { height: 300 });
        to.restoreView(from.view);

        compare(to.currentSection, "ControlCenter");
        compare(to.sectionQuery, "tiles");
        compare(all(to, child => child.placeholderText === "Search settings")[0].text, "tiles");
        tryCompare(sectionScrollOf(to), "contentY", 60, 1000);
    }

    // The view follows the panel as it is used.
    function test_thePanelsViewFollowsItsSectionSearchAndScroll() {
        const item = createTemporaryObject(panel, this, { height: 300 });
        item.openSection("ControlCenter");
        item.sectionQuery = "tiles";
        const scroll = sectionScrollOf(item);
        tryVerify(() => scroll.contentHeight > scroll.height + 40, 1000, "the section doesn't scroll");
        scroll.contentY = 40;

        compare(item.view.section, "ControlCenter");
        compare(item.view.query, "tiles");
        compare(item.view.scroll, 40);
    }

    // The section shown: what the sidebar row opened, under the title.
    function sectionShown(item) {
        return all(item, child => child.objectName === "sectionContent")[0].item;
    }

    // The sections that need Quickshell (Hyprland's monitors, running a
    // process) can't be built here; their own tests check their cards.
    readonly property var quickshellSections: ["Widgets", "Session", "Wallpapers"]

    function cardedSections(item) {
        return item.sections.filter(entry => !quickshellSections.includes(entry.section));
    }

    // The card holding `child` inside `section`, or null when it sits outside
    // every card.
    function cardOf(child, section) {
        for (let parent = child.parent; parent && parent !== section; parent = parent.parent) {
            if (parent instanceof Panels.SettingsCard)
                return parent;
        }
        return null;
    }

    // Every headed group in every section sits in a card, and nothing is left
    // outside one but the section's own title and description; the text in
    // a card stays inside its 16px padding.
    function test_everythingInEverySectionSitsInACard() {
        const item = createTemporaryObject(panel, this);

        for (const entry of cardedSections(item)) {
            item.openSection(entry.section);
            const section = sectionShown(item);
            verify(section, entry.section + " is not shown");
            const texts = all(section, child => child.visible && child.font !== undefined
                && typeof child.text === "string" && child.text !== "");

            verify(all(section, child => child instanceof Panels.SettingsCard && child.visible).length > 0,
                entry.section + " has no card");
            for (const text of texts) {
                const card = cardOf(text, section);
                verify(card, entry.section + ": \"" + text.text + "\" is outside every card");
                const left = text.mapToItem(card, 0, 0).x;
                verify(left >= 16 && left + text.width <= card.width - 16 + 0.5,
                    entry.section + ": \"" + text.text + "\" runs past its card's padding");
            }
        }
    }

    // Cards follow one another 12px apart, and a card holds no other card.
    function test_cardsAreTwelvePixelsApart() {
        const item = createTemporaryObject(panel, this);

        for (const entry of cardedSections(item)) {
            item.openSection(entry.section);
            const section = sectionShown(item);
            verify(section, entry.section + " is not shown");
            const cards = all(section, child => child instanceof Panels.SettingsCard && child.visible)
                .map(card => ({ card: card, y: card.mapToItem(section, 0, 0).y }))
                .sort((a, b) => a.y - b.y);

            for (let i = 0; i < cards.length; i++) {
                verify(!cardOf(cards[i].card, section), entry.section + ": a card inside a card");
                if (i > 0)
                    compare(cards[i].y - (cards[i - 1].y + cards[i - 1].card.height), 12,
                        entry.section + ": the gap above card " + i);
            }
        }
    }
}
