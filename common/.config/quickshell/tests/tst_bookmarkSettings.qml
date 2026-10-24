import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Quick Search section, built from the settings parts: bookmarks and
// search engines as full-width rows, transparent until hovered, with their
// short fields paired on one line.
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
}
