import QtQuick
import QtTest
import "../components/panels/EmojiSearch.js" as EmojiSearch

// The emoji picker's matching: which emoji a name after ":" finds, best first.
TestCase {
    name: "EmojiSearch"

    function emojiOf(matches) {
        return matches.map(match => match.emoji);
    }

    function test_anEmojiIsFoundByItsName() {
        compare(EmojiSearch.matches("fire", 10)[0], { emoji: "🔥", name: "fire" });
        compare(EmojiSearch.matches("rocket", 10)[0].emoji, "🚀");
    }

    function test_theSearchIgnoresCaseAndSpaces() {
        compare(EmojiSearch.matches("  FiRe ", 10)[0].emoji, "🔥");
    }

    function test_anEmojiIsFoundByItsShortcode() {
        compare(EmojiSearch.matches("tada", 10)[0].emoji, "🎉");
        compare(EmojiSearch.matches("+1", 10)[0].emoji, "👍");
    }

    function test_aFlagIsFoundByItsCountry() {
        compare(EmojiSearch.matches("spain", 10)[0].emoji, "🇪🇸");
    }

    function test_everyWordHasToStartAWordOfTheName() {
        const found = emojiOf(EmojiSearch.matches("tears joy", 10));

        verify(found.includes("😂"));
        verify(found.includes("😹"));
        verify(!found.includes("🔥"));
        compare(EmojiSearch.matches("ire", 10).map(match => match.emoji).includes("🔥"), false);
    }

    function test_aNameThatIsTheQueryComesBeforeLongerNames() {
        const found = emojiOf(EmojiSearch.matches("heart", 50));

        verify(found.length > 1);
        compare(found[0], "❤️");
    }

    function test_aNameThatStartsWithTheQueryComesBeforeOneThatOnlyContainsIt() {
        const found = emojiOf(EmojiSearch.matches("cat", 50));

        verify(found.indexOf("🐈") >= 0);
        verify(found.indexOf("😸") >= 0);
        verify(found.indexOf("🐈") < found.indexOf("😸"));
    }

    function test_noMoreThanTheLimitAreListed() {
        compare(EmojiSearch.matches("face", 5).length, 5);
    }

    function test_nothingMatchingListsNothing() {
        compare(EmojiSearch.matches("qwertyuiop", 10), []);
    }

    function test_noNameListsTheCommonOnesInTheirOrder() {
        const common = EmojiSearch.matches("", 100);

        verify(common.length >= 10);
        compare(common[0].emoji, "😂");
        compare(EmojiSearch.matches("", 3).length, 3);
        verify(common.every(match => match.name !== ""));
    }
}
