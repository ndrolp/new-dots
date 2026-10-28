import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config/Motion.js" as Motion
import "../config" as Config

// The Plugins section, built from the settings parts: each plugin's on/off is
// a switch row in a full-width list, and the plugins' own settings sit two
// per line.
TestCase {
    name: "PluginSettings"
    width: 800
    height: 1400
    when: windowShown

    Config.Theme {
        id: theme
    }

    function all(item, predicate, found) {
        found = found || [];
        if (predicate(item))
            found.push(item);
        for (let i = 0; i < item.children.length; i++)
            all(item.children[i], predicate, found);
        return found;
    }

    function numberCell(item, label) {
        return all(item, child => child.label === label && child.field !== undefined)[0];
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    // Where the settings panel shows a section: the section sizes itself to it. A
    // fake plugins object stands in for the shell's; the section writes to it.
    Component {
        id: sectionArea

        Item {
            property alias plugins: plugins
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                readonly property var motion: Motion.motion(false)
            }

            QtObject {
                id: plugins

                property bool applicationLauncherEnabled: true
                property bool clipboardEnabled: true
                property bool quickSearchEnabled: false
                property bool unifiedSearchEnabled: true
                property bool quickSettingsEnabled: true
                property bool commandLauncherEnabled: true
                property bool screenCaptureEnabled: true
                property bool controlCenterEnabled: true
                property int launcherRecentLimit: 8
                property bool clipboardImagePreviewsEnabled: false
            }

            Panels.PluginSettings {
                id: section

                appearance: appearance
                plugins: plugins
            }
        }
    }

    function make() {
        const built = createTemporaryObject(sectionArea, this);
        return { plugins: built.plugins, item: built.section };
    }

    function test_eachPluginsSwitchRowShowsAndTogglesWhetherItIsEnabled() {
        const built = make();
        const rows = [
            ["Application launcher", "applicationLauncherEnabled"],
            ["Clipboard history", "clipboardEnabled"],
            ["Quick search", "quickSearchEnabled"],
            ["Unified search", "unifiedSearchEnabled"],
            ["Quick settings", "quickSettingsEnabled"],
            ["Command launcher", "commandLauncherEnabled"],
            ["Screen capture", "screenCaptureEnabled"],
            ["Control center", "controlCenterEnabled"]
        ];

        for (const pair of rows) {
            const row = switchRow(built.item, pair[0]);
            verify(row, pair[0]);
            const before = built.plugins[pair[1]];
            compare(row.checked, before, pair[0]);

            row.toggled();
            compare(built.plugins[pair[1]], !before, pair[0]);
            compare(row.checked, !before, pair[0]);
        }
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function textShown(item, text) {
        return all(item, child => child.text === text && child.font !== undefined
            && !(child instanceof TextInput)).length > 0;
    }

    function test_clipboardImagePreviewsSayWhatTheyDo() {
        const built = make();

        verify(textShown(built.item, "Decode copied images for preview in clipboard history."));
    }

    function test_thePluginsOwnSettingsSitTwoPerLineAndStillSave() {
        const built = make();
        const recent = numberCell(built.item, "Launcher recent apps");
        const previews = switchRow(built.item, "Clipboard image previews");

        verify(recent);
        verify(previews);
        verify(sameLine(built.item, recent, previews));
        compare(recent.value, 8);

        recent.field.forceActiveFocus();
        recent.field.selectAll();
        keyClick("1");
        keyClick("2");
        keyClick(Qt.Key_Return);
        compare(built.plugins.launcherRecentLimit, 12);
        compare(recent.value, 12);

        recent.slider.forceActiveFocus();
        keyClick(Qt.Key_Right);
        compare(built.plugins.launcherRecentLimit, 13);

        compare(previews.checked, false);
        previews.toggled();
        compare(built.plugins.clipboardImagePreviewsEnabled, true);
        compare(previews.checked, true);
    }

    function test_nothingIsBoldAndNoFilledCardsRemain() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        // A card is a filled box around a setting; the slider's thin track
        // and the switches' pills are not.
        const cards = all(built.item, child => child instanceof Rectangle
            && child.height >= 40 && child.color.a > 0);

        compare(bold.length, 0);
        compare(cards.length, 0);
    }
}
