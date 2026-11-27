import QtQuick
import QtTest
import "../components/panels" as Panels
import "../components/panels/SettingsSearch.js" as SettingsSearch
import "../config" as Config
import "../config/Motion.js" as Motion
import "../config/ControlCenterTiles.js" as ControlCenterTiles
import "../config/DesktopWidgetsModel.js" as DesktopWidgetsModel

// Settings search lands on the setting: it matches setting labels as well as
// section keywords, lists the matching settings under their section in the
// sidebar, and choosing one opens its section, scrolls to it and flashes it.
TestCase {
    name: "SettingsSearch"
    width: 1000
    height: 600
    visible: true
    when: windowShown

    Config.Theme {
        id: theme
    }

    // What every section the panel can build here reads.
    QtObject {
        id: fakeAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(false)
        property bool reduceMotion: false
        property string notificationPopupLocation: "top-right"
        readonly property var controlCenterTiles: ControlCenterTiles.defaultTiles()
        property var barProfiles: ({ "work": {} })
        property string editingBarProfile: "work"
        property bool barProfileModified: false
        property string barPosition: "top"
        property string barStyle: "transparent"
        property int iconSize: 13
        property int barHeight: 32
        property int barOpacity: 90
        property int horizontalPadding: 12
        property int pillVerticalPadding: 4
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

        function setBarSetting(name, value) {}
        function applyDensityPreset(preset) {}
        function barElementOption(element, option) { return false; }
        function setBarElementOption(element, option, value) {}
        function duplicateNameError(name) { return ""; }
        function renameNameError(name) { return ""; }
        function deleteBarProfileRejection(profile, displaySettings) { return ""; }
        function suggestedDuplicateName() { return "work 2"; }
    }

    // What the Plugins section reads; a missing switch reads as off.
    QtObject {
        id: fakePlugins

        property int launcherRecentLimit: 10
        property bool clipboardImagePreviewsEnabled: false
    }

    // What the Displays section reads: one monitor and its setup.
    QtObject {
        id: fakeMonitors

        function rangeFor(description) { return { from: 1, to: 5 }; }
        function displaySettingsFor(description) { return { barVisible: true, barProfile: "work" }; }
    }

    QtObject {
        id: fakeSetups

        property var entries: [{ description: "AOC", port: "DP-2", mode: "2560x1440@143.91", position: "0x0",
            scale: 1, transform: 0, disabled: false, mirror: "" }]
        property var savedSetups: []
        property bool counting: false

        function modesOf(port) { return [{ width: 2560, height: 1440, refresh: 143.91 }]; }
    }

    Component {
        id: panel

        Panels.ConfigPanel {
            appearance: fakeAppearance
            monitors: fakeMonitors
            monitorSetups: fakeSetups
            wallpapers: null
            bookmarks: null
            plugins: null
            currentSection: "Notifications"
        }
    }

    function init() {
        fakeAppearance.barStyle = "transparent";
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    // What the search lists: each section's label with the labels of its
    // matching settings.
    function listed(item) {
        return item.filteredSections.map(section => [section.label].concat(
            section.settings.map(setting => setting.label)));
    }

    function test_aSettingsLabelListsItUnderItsSection() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "edge margin" });

        compare(listed(item), [["Bar", "Edge margin"]]);
    }

    function test_aCapsuleSettingIsListedOnACapsule() {
        fakeAppearance.barStyle = "capsule";
        const item = createTemporaryObject(panel, this, { sectionQuery: "notifications in the capsule" });

        compare(listed(item), [["Bar", "Notifications in the capsule"]]);
    }

    // A setting the edited profile's bar style doesn't use isn't offered; a
    // section its keywords find is still listed.
    function test_aSettingTheBarStyleHidesIsNotOffered() {
        fakeAppearance.barStyle = "opaque";
        const item = createTemporaryObject(panel, this, { sectionQuery: "edge margin" });
        compare(listed(item), [["Bar"]]);

        item.sectionQuery = "notifications in the capsule";
        compare(listed(item), []);
    }

    // Changing the bar style changes what is offered straight away.
    function test_whatIsOfferedFollowsTheBarStyle() {
        fakeAppearance.barStyle = "opaque";
        const item = createTemporaryObject(panel, this, { sectionQuery: "edge margin" });

        fakeAppearance.barStyle = "capsule";

        compare(listed(item), [["Bar", "Edge margin"]]);
    }

    function test_theGapsAreListedUnderWindows_data() {
        return [
            { tag: "inner", query: "inner gaps", listed: [["Windows", "Inner gaps"]] },
            { tag: "outer", query: "outer gaps", listed: [["Windows", "Outer gaps"]] },
            { tag: "both", query: "gaps", listed: [["Windows", "Inner gaps", "Outer gaps"]] }
        ];
    }

    function test_theGapsAreListedUnderWindows(data) {
        const item = createTemporaryObject(panel, this, { sectionQuery: data.query });

        compare(listed(item), data.listed);
    }

    // The Windows section's keywords find it.
    function test_theWindowsKeywordsFindIt_data() {
        return ["hyprland", "gaps", "rounding", "decoration", "transparency", "inactive", "appearance"]
            .map(query => ({ tag: query, query: query }));
    }

    function test_theWindowsKeywordsFindIt(data) {
        const item = createTemporaryObject(panel, this, { sectionQuery: data.query });

        verify(item.filteredSections.some(section => section.label === "Windows"),
            "\"" + data.query + "\" doesn't find the Windows section");
    }

    function test_sectionOnlyMatchesListNoSettings() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "animations" });

        compare(listed(item), [["Motion"]]);
    }

    function test_anEmptySearchListsEverySectionAndNoSettings() {
        const item = createTemporaryObject(panel, this);

        compare(item.filteredSections.length, item.sections.length);
        verify(item.filteredSections.every(section => section.settings.length === 0));
    }

    // A setting found in a section the keywords don't name lists the section.
    function test_aSettingFindsASectionItsKeywordsDont() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "glyphs" });

        compare(listed(item), [["Workspace Labels", "Use workspace glyphs"]]);
    }

    // The sidebar row showing `text`.
    function sidebarRowOf(item, text) {
        const sidebar = all(item, child => child.objectName === "sectionSidebar")[0];
        return all(sidebar, child => child.clickable === true
            && all(child, inner => inner.text === text && inner.visible).length > 0)[0] || null;
    }

    function yOf(child, item) {
        return child.mapToItem(item, 0, 0).y;
    }

    // A listed setting is a clickable sidebar row of its own, right under its
    // section's row and indented past it.
    function test_theSidebarListsASettingUnderItsSection() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "padding" });
        const bar = sidebarRowOf(item, "Bar");
        const setting = sidebarRowOf(item, "Horizontal padding");
        const widgets = sidebarRowOf(item, "Desktop Widgets");

        verify(bar, "no Bar row");
        verify(setting, "no row for the setting");
        verify(widgets, "no Desktop Widgets row");
        verify(yOf(setting, item) > yOf(bar, item), "the setting is above its section");
        verify(yOf(setting, item) < yOf(widgets, item), "the setting is under another section");
        const label = all(setting, inner => inner.text === "Horizontal padding")[0];
        const sectionLabel = all(bar, inner => inner.text === "Bar")[0];
        verify(label.mapToItem(item, 0, 0).x > sectionLabel.mapToItem(item, 0, 0).x, "not indented");
    }

    // The section's scroll area.
    function sectionScrollOf(item) {
        return all(item, child => child.objectName === "sectionScroll")[0];
    }

    // The shown setting labelled `label` in the section shown.
    function settingShown(item, label) {
        const content = all(item, child => child.objectName === "sectionContent")[0].item;
        return content ? all(content, child => child.visible && child.label === label)[0] || null : null;
    }

    // Whether `setting` sits wholly inside the section's scroll area.
    function inView(item, setting) {
        const scroll = sectionScrollOf(item);
        const top = setting.mapToItem(scroll, 0, 0).y;
        return top >= 0 && top + setting.height <= scroll.height;
    }

    function highlightOf(item) {
        return all(item, child => child.objectName === "settingHighlight")[0];
    }

    // Choosing a listed setting opens its section, scrolls it into view and
    // flashes the accent over it, which then fades away.
    function test_choosingASettingOpensScrollsToAndFlashesIt() {
        const item = createTemporaryObject(panel, this, { height: 300, sectionQuery: "group border" });
        mouseClick(sidebarRowOf(item, "Group border"));

        tryCompare(item, "currentSection", "Bar", 1000);
        tryVerify(() => settingShown(item, "Group border") !== null, 1000, "the setting isn't shown");
        const setting = settingShown(item, "Group border");
        tryVerify(() => inView(item, setting), 1000, "the setting isn't scrolled into view");
        verify(sectionScrollOf(item).contentItem.contentY > 0, "the section didn't scroll");

        const highlight = highlightOf(item);
        verify(highlight, "no highlight");
        tryVerify(() => highlight.opacity > 0, 1000, "the setting isn't highlighted");
        verify(Qt.colorEqual(Qt.rgba(highlight.color.r, highlight.color.g, highlight.color.b, 1), theme.accent),
            "the highlight isn't the accent");
        const at = setting.mapToItem(highlight.parent, 0, 0);
        verify(highlight.y <= at.y && highlight.y + highlight.height >= at.y + setting.height,
            "the highlight isn't over the setting");
        tryCompare(highlight, "opacity", 0, 3000);
    }

    // Enter on the search goes to the first setting listed.
    function test_enterGoesToTheFirstListedSetting() {
        const item = createTemporaryObject(panel, this, { height: 300 });
        const search = all(item, child => child.placeholderText === "Search settings")[0];
        search.forceActiveFocus();
        search.text = "";
        keyClick(Qt.Key_E); keyClick(Qt.Key_D); keyClick(Qt.Key_G); keyClick(Qt.Key_E);
        keyClick(Qt.Key_Space); keyClick(Qt.Key_M);
        compare(item.sectionQuery, "edge m");

        keyClick(Qt.Key_Return);

        tryCompare(item, "currentSection", "Bar", 1000);
        tryVerify(() => settingShown(item, "Edge margin") !== null
            && inView(item, settingShown(item, "Edge margin")), 1000, "Edge margin isn't in view");
        tryVerify(() => highlightOf(item).opacity > 0, 1000, "Edge margin isn't highlighted");
    }

    // Enter on a search that finds only sections opens the first one.
    function test_enterOnASectionOnlySearchOpensTheSection() {
        const item = createTemporaryObject(panel, this);
        const search = all(item, child => child.placeholderText === "Search settings")[0];
        item.sectionQuery = "tiles";
        search.forceActiveFocus();

        keyClick(Qt.Key_Return);

        tryCompare(item, "currentSection", "ControlCenter", 1000);
    }

    // Choosing a setting of the section shown scrolls to it too.
    function test_choosingASettingOfTheShownSectionScrollsToIt() {
        const item = createTemporaryObject(panel, this, { height: 300, currentSection: "Bar", sectionQuery: "group border" });
        tryVerify(() => settingShown(item, "Group border") !== null, 1000);
        const setting = settingShown(item, "Group border");
        verify(!inView(item, setting), "it starts in view");

        mouseClick(sidebarRowOf(item, "Group border"));

        tryVerify(() => inView(item, setting), 1000, "the setting isn't scrolled into view");
        tryVerify(() => highlightOf(item).opacity > 0, 1000, "the setting isn't highlighted");
    }

    // The labels of the settings shown in the section shown.
    function labelledSettingsShown(item) {
        return labelledSettingsIn(all(item, child => child.objectName === "sectionContent")[0].item);
    }

    // The labels of the settings shown in `content`: whatever shown carries a
    // label (a field, a switch row, a tile's row, a session action) but a
    // button, which does something rather than set something.
    function labelledSettingsIn(content) {
        return all(content, child => child.visible && typeof child.label === "string" && child.label !== ""
            && child.labelColor === undefined && ancestorsVisible(child, content))
            .map(setting => setting.label);
    }

    function ancestorsVisible(child, top) {
        for (let parent = child.parent; parent && parent !== top; parent = parent.parent) {
            if (!parent.visible)
                return false;
        }
        return true;
    }

    // Sections that need Quickshell to show their settings; the parts that
    // show them are checked on their own below.
    readonly property var unbuiltSections: ["Widgets", "Session", "Wallpapers"]

    // The search's index of settings matches what each section shows, on
    // every bar style: every setting offered is shown under its label, and
    // every labelled setting shown is offered, so a new or renamed setting
    // can't be missed by the search.
    function test_theIndexMatchesWhatEachSectionShows_data() {
        return ["opaque", "transparent", "docked", "capsule"].map(style => ({ tag: style, style: style }));
    }

    function test_theIndexMatchesWhatEachSectionShows(data) {
        fakeAppearance.barStyle = data.style;
        const item = createTemporaryObject(panel, this, { plugins: fakePlugins });

        for (const entry of item.sections.filter(entry => !unbuiltSections.includes(entry.section))) {
            item.openSection(entry.section);
            waitForRendering(item);
            const offered = SettingsSearch.offeredSettings(entry, data.style).map(setting => setting.label);
            const shown = labelledSettingsShown(item);

            for (const label of offered)
                verify(shown.includes(label), entry.section + " doesn't show \"" + label + "\"");
            // A list's entries (a glyph per workspace) are not settings of their own.
            for (const label of shown.filter(label => !/^Workspace \d+$/.test(label)))
                verify(offered.includes(label), entry.section + ": \"" + label + "\" isn't offered by the search");
        }
    }

    // What the sections that need Quickshell are built from, with fakes.
    Component {
        id: widgetsPart

        Panels.DesktopWidgetsMonitorSettings {
            width: 700
            appearance: fakeAppearance
            monitors: QtObject {
                // The Cava progress line on, so its color shows too.
                property var displaySettings: DesktopWidgetsModel.setDesktopWidgetSetting(
                    {}, "AOC", "cava", "progress", "line")

                function desktopWidgetsFor(monitorName) {
                    return DesktopWidgetsModel.desktopWidgetsFor(displaySettings, monitorName);
                }

                function desktopWidgetOrder(monitorName) {
                    return DesktopWidgetsModel.desktopWidgetOrder(desktopWidgetsFor(monitorName));
                }
            }
            monitorName: "AOC"
        }
    }

    Component {
        id: sessionPart

        Panels.SessionActions {
            width: 700
            appearance: fakeAppearance
        }
    }

    Component {
        id: wallpapersPart

        Panels.WallpaperSettingsBody {
            width: 700
            appearance: fakeAppearance
            wallpapers: QtObject {
                property string horizontalFolder: "/walls/h"
                property string verticalFolder: "/walls/v"
                property bool dynamicEnabled: false
                property int dynamicIntervalMinutes: 30
                property var horizontalWallpapers: []
                property var verticalWallpapers: []

                function pathFor(description) { return ""; }
            }
            displays: [{ description: "AOC", name: "Q27G2", portrait: false }]
            selectedWallpaperMonitor: "AOC"
        }
    }

    // The index matches what the sections that need Quickshell show, through
    // the parts they are built from: every setting offered is shown in the
    // view it names (one of Wallpapers' views; none, the first view), and
    // every labelled setting shown in a view is offered for it.
    function test_theIndexMatchesWhatTheUnbuiltSectionsShow_data() {
        return [
            { tag: "Widgets", component: widgetsPart, views: [""] },
            { tag: "Session", component: sessionPart, views: [""] },
            { tag: "Wallpapers", component: wallpapersPart, views: ["Selection", "Locations", "Schedule"] }
        ];
    }

    function test_theIndexMatchesWhatTheUnbuiltSectionsShow(data) {
        const item = createTemporaryObject(panel, this);
        const entry = item.sections.find(entry => entry.section === data.tag);
        const part = createTemporaryObject(data.component, this);
        const offered = SettingsSearch.offeredSettings(entry, fakeAppearance.barStyle);

        for (const view of data.views) {
            if (view !== "")
                part.wallpaperView = view;
            waitForRendering(part);
            const shown = labelledSettingsIn(part);
            const offeredHere = offered
                .filter(setting => (setting.view || data.views[0]) === view)
                .map(setting => setting.label);

            for (const label of offeredHere)
                verify(shown.includes(label), data.tag + " " + view + " doesn't show \"" + label + "\"");
            for (const label of shown)
                verify(offeredHere.includes(label), data.tag + " " + view + ": \"" + label + "\" isn't offered by the search");
        }
    }

    function test_aWallpapersScheduleSettingIsListed() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "scheduled rotation" });

        compare(listed(item), [["Wallpapers", "Enable scheduled rotation"]]);
    }

    // Choosing a Wallpapers setting of a view not shown switches to that view
    // first, so there is something to scroll to.
    function test_choosingASettingOfAnotherWallpapersViewSwitchesToIt() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "interval", wallpaperView: "Selection" });
        mouseClick(sidebarRowOf(item, "Interval (minutes)"));

        tryCompare(item, "currentSection", "Wallpapers", 1000);
        compare(item.wallpaperView, "Schedule");
    }

    function test_enterOnASettingOfAnotherWallpapersViewSwitchesToIt() {
        const item = createTemporaryObject(panel, this, { wallpaperView: "Locations" });
        const search = all(item, child => child.placeholderText === "Search settings")[0];
        item.sectionQuery = "scheduled rotation";
        search.forceActiveFocus();

        keyClick(Qt.Key_Return);

        tryCompare(item, "currentSection", "Wallpapers", 1000);
        compare(item.wallpaperView, "Schedule");
    }

    // A tile of the control center is found by the name the section gives it.
    function test_aControlCenterTileIsListed() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "night light" });

        compare(listed(item), [["Control center", "Night light"]]);
    }

    // Enter on a search that finds only sections goes to the section, with no setting.
    function test_firstMatchOfASectionOnlySearchHasNoSetting() {
        const item = createTemporaryObject(panel, this, { sectionQuery: "animations" });

        compare(SettingsSearch.firstMatch(item.filteredSections), { section: "Motion", setting: null });
    }
}
