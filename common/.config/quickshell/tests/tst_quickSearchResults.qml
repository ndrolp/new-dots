import QtQuick
import QtTest
import "../components/panels/QuickSearchResults.js" as QuickSearchResults

// The bookmarks quick search shows: at most two rows of five, in the order
// of the settings, with the rest reached only by typing.
TestCase {
    name: "QuickSearchResults"

    function bookmarks(count) {
        const items = [];
        for (let index = 1; index <= count; index++)
            items.push({ label: "Site " + index, url: "https://site" + index + ".example" });
        return items;
    }

    function labels(items) {
        return items.map(item => item.label);
    }

    function test_withNoQueryItShowsTheFirstTenInTheSettingsOrder() {
        const shown = QuickSearchResults.shown(bookmarks(14), "");

        compare(shown.length, 10);
        compare(shown[0].label, "Site 1");
        compare(shown[9].label, "Site 10");
    }

    function test_fewerThanTenAreAllShown() {
        compare(QuickSearchResults.shown(bookmarks(3), "").length, 3);
    }

    function test_aBookmarkPastTheTenthIsFoundByTyping() {
        compare(labels(QuickSearchResults.shown(bookmarks(14), "site 13")), ["Site 13"]);
    }

    function test_theQueryMatchesTheUrlTooIgnoringCaseAndSpaces() {
        const items = [{ label: "Mail", url: "https://Fastmail.com" }, { label: "News", url: "https://news.example" }];

        compare(labels(QuickSearchResults.shown(items, "  fastmail ")), ["Mail"]);
    }

    function test_moreThanTenMatchesShowTheFirstTenInTheSettingsOrder() {
        const shown = QuickSearchResults.shown(bookmarks(25), "site");

        compare(shown.length, 10);
        compare(shown[0].label, "Site 1");
        compare(shown[9].label, "Site 10");
    }

    function test_rowsAreFiveAcrossAndAtMostTwo() {
        compare(QuickSearchResults.rows(0), 0);
        compare(QuickSearchResults.rows(3), 1);
        compare(QuickSearchResults.rows(5), 1);
        compare(QuickSearchResults.rows(6), 2);
        compare(QuickSearchResults.rows(10), 2);
    }
}
