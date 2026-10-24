import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Quick Search section, built from the settings parts: bookmarks and
// search engines as full-width rows, transparent until hovered, with their
// short fields paired on one line. Pointer events don't reach items under
// qmltestrunner offscreen, so buttons are pressed by their signal and a
// button that can't be pressed is checked by being disabled.
TestCase {
    name: "BookmarkSettings"
    width: 800
    height: 1200
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

    function rows(item, kind) {
        return all(item, child => child.rowKind === kind);
    }

    function field(row, name) {
        return all(row, child => child.fieldName === name)[0];
    }

    function button(item, label) {
        return all(item, child => child.label === label && child.activated !== undefined)[0];
    }

    // The settings panel's page: the section sizes itself to it. A fake
    // bookmarks store stands in for the shell's and records what is asked.
    Component {
        id: page

        Item {
            property alias bookmarks: bookmarks
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
            }

            QtObject {
                id: bookmarks

                property var items: [
                    { label: "GitHub", glyph: "G", url: "https://github.com" },
                    { label: "Mail", glyph: "M", url: "https://mail.example.com" }
                ]
                property var searchEngines: [
                    { label: "DuckDuckGo", glyph: "D", searchUrl: "https://duckduckgo.com/?q=%s" }
                ]
                property var calls: []

                function record(call) {
                    calls = calls.concat([call]);
                }

                function add() { record(["add"]); }
                function remove(index) { record(["remove", index]); }
                function move(from, to) { record(["move", from, to]); }
                function update(index, key, value) { record(["update", index, key, value]); }
                function addSearchEngine() { record(["addSearchEngine"]); }
                function removeSearchEngine(index) { record(["removeSearchEngine", index]); }
                function moveSearchEngine(from, to) { record(["moveSearchEngine", from, to]); }
                function updateSearchEngine(index, key, value) {
                    record(["updateSearchEngine", index, key, value]);
                }
            }

            Panels.BookmarkSettings {
                id: section

                appearance: appearance
                bookmarks: bookmarks
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { bookmarks: built.bookmarks, item: built.section };
    }

    function sameLine(item, first, second) {
        const a = first.mapToItem(item, 0, 0);
        const b = second.mapToItem(item, 0, 0);
        return a.y === b.y && a.x < b.x;
    }

    function press(item) {
        verify(item.enabled, item.label);
        item.activated();
    }

    // Leaving a field also finishes its edit, so the same save can be asked
    // twice in a row; that is harmless and not what these tests are about.
    function distinct(calls) {
        return calls.filter((call, i) => i === 0 || JSON.stringify(call) !== JSON.stringify(calls[i - 1]));
    }

    function typeInto(input, text) {
        input.forceActiveFocus();
        input.selectAll();
        for (const character of text)
            keyClick(character);
        keyClick(Qt.Key_Return);
    }

    function test_bookmarksAreFullWidthRowsTransparentUntilHovered() {
        const built = make();
        const bookmarkRows = rows(built.item, "bookmark");

        compare(bookmarkRows.length, 2);
        for (const row of bookmarkRows) {
            compare(row.width, built.item.width);
            compare(row.color, Qt.rgba(0, 0, 0, 0));
        }
    }

    function test_aBookmarksGlyphAndNameSitOnOneLineAndItsUrlBelow() {
        const built = make();
        const row = rows(built.item, "bookmark")[0];
        const glyph = field(row, "glyph");
        const name = field(row, "label");
        const url = field(row, "url");

        verify(sameLine(built.item, glyph, name));
        verify(url.mapToItem(built.item, 0, 0).y > name.mapToItem(built.item, 0, 0).y);
        compare(glyph.background.color, Qt.rgba(0, 0, 0, 0));
        compare(glyph.background.border.color, theme.border);
    }

    function test_editingABookmarkStillSavesIt() {
        const built = make();
        const row = rows(built.item, "bookmark")[1];

        typeInto(field(row, "label"), "Inbox");
        typeInto(field(row, "url"), "https://x.io");

        compare(distinct(built.bookmarks.calls), [
            ["update", 1, "label", "Inbox"],
            ["update", 1, "url", "https://x.io"]
        ]);
    }

    function test_addingMovingAndRemovingBookmarksStillWork() {
        const built = make();
        const [first, second] = rows(built.item, "bookmark");

        press(button(built.item, "󰐕  Add bookmark"));
        press(button(first, "󰁅"));
        press(button(second, "󰁝"));
        press(button(second, "Remove"));

        compare(built.bookmarks.calls, [["add"], ["move", 0, 1], ["move", 1, 0], ["remove", 1]]);
    }

    function test_theEndBookmarksCannotMovePastTheEnds() {
        const built = make();
        const [first, last] = rows(built.item, "bookmark");

        verify(!button(first, "󰁝").enabled);
        verify(!button(last, "󰁅").enabled);
    }

    function test_searchEnginesAreEditedAddedAndMovedLikeBookmarks() {
        const built = make();
        const row = rows(built.item, "searchEngine")[0];

        compare(row.width, built.item.width);
        verify(sameLine(built.item, field(row, "glyph"), field(row, "label")));
        typeInto(field(row, "searchUrl"), "q=%s");
        press(button(built.item, "󰐕  Add search engine"));

        compare(distinct(built.bookmarks.calls), [["updateSearchEngine", 0, "searchUrl", "q=%s"], ["addSearchEngine"]]);
    }

    function test_theLastSearchEngineCannotBeRemoved() {
        const built = make();
        const row = rows(built.item, "searchEngine")[0];

        verify(!button(row, "Remove").enabled);

        built.bookmarks.searchEngines = built.bookmarks.searchEngines.concat([
            { label: "Wiki", glyph: "W", searchUrl: "https://wiki.example.com/?q=%s" }
        ]);
        press(button(rows(built.item, "searchEngine")[1], "Remove"));
        compare(built.bookmarks.calls, [["removeSearchEngine", 1]]);
    }

    function test_nothingIsBoldAndNoFilledCardsRemain() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        const filled = all(built.item, child => child instanceof Rectangle && child.visible
            && child.color.a > 0);

        compare(bold.length, 0);
        compare(filled.length, 0);
    }
}
