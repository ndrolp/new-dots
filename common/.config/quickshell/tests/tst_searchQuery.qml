import QtQuick
import QtTest
import "../components/panels/SearchQuery.js" as SearchQuery

// What a unified search query asks for: the mode its prefix picks, whether it
// is maths for the calculator, and the answer qalc gives back.
TestCase {
    name: "SearchQuery"

    function test_aLeadingPrefixPicksTheModeAndIsLeftOutOfTheText() {
        compare(SearchQuery.mode(" > htop"), { mode: "commands", text: "htop" });
        compare(SearchQuery.mode("?weather"), { mode: "web", text: "weather" });
        compare(SearchQuery.mode("@ kitty "), { mode: "windows", text: "kitty" });
        compare(SearchQuery.mode("= pi"), { mode: "calculator", text: "pi" });
        compare(SearchQuery.mode(":fire"), { mode: "emoji", text: "fire" });
        compare(SearchQuery.mode(":"), { mode: "emoji", text: "" });
    }

    function test_aQueryWithoutAPrefixSearchesEverything() {
        compare(SearchQuery.mode(" firefox "), { mode: "", text: "firefox" });
        compare(SearchQuery.mode(""), { mode: "", text: "" });
    }

    function test_aLeadingEqualsAlwaysAsksTheCalculator() {
        compare(SearchQuery.calculation("=pi"), "pi");
        compare(SearchQuery.calculation("= firefox"), "firefox");
        compare(SearchQuery.calculation("="), "");
    }

    function test_mathsIsSentToTheCalculator() {
        compare(SearchQuery.calculation("2*(3+4)"), "2*(3+4)");
    }

    function test_aUnitConversionIsSentToTheCalculator() {
        compare(SearchQuery.calculation("5 km to mi"), "5 km to mi");
        compare(SearchQuery.calculation("1.5GiB in MB"), "1.5GiB in MB");
        compare(SearchQuery.calculation("30 °C to °F"), "30 °C to °F");
        compare(SearchQuery.calculation("100 USD to EUR"), "100 USD to EUR");
    }

    function test_aFunctionOfANumberIsSentToTheCalculator() {
        compare(SearchQuery.calculation("sqrt(16)"), "sqrt(16)");
        compare(SearchQuery.calculation("log(100) * 2"), "log(100) * 2");
        compare(SearchQuery.calculation("Steam (2)"), "");
    }

    // qalc reads "of" as a unit, so the shell asks for the product instead.
    function test_aPercentageOfANumberIsAskedAsAProduct() {
        compare(SearchQuery.calculation("20% of 80"), "20% * 80");
        compare(SearchQuery.calculation("12.5 % OF 200"), "12.5% * 200");
        compare(SearchQuery.calculation("= 20% of 80"), "20% * 80");
    }

    function test_anotherPrefixIsNeverMaths() {
        compare(SearchQuery.calculation("> 2+2"), "");
        compare(SearchQuery.calculation("?5 km to mi"), "");
        compare(SearchQuery.calculation(":1+1"), "");
    }

    function test_qalcGetsTheExpressionAsOneArgumentNeverThroughAShell() {
        const command = SearchQuery.qalcCommand("1+1; rm -rf ~ $(id)");
        compare(command.slice(command.indexOf("qalc")), ["qalc", "-t", "1+1; rm -rf ~ $(id)"]);
    }

    function test_qalcsAnswerIsWhatItPrintsLast() {
        compare(SearchQuery.answer(["14"], 0), "14");
        compare(SearchQuery.answer(["", "  86 °F ", ""], 0), "86 °F");
    }

    // qalc still prints a guess when it can't read the expression, but exits 1.
    function test_qalcFailingGivesNoAnswer() {
        compare(SearchQuery.answer(["5.08iy ps·t²·m³"], 1), "");
        compare(SearchQuery.answer([], 0), "");
    }

    function test_anAppSearchIsNotMaths() {
        compare(SearchQuery.calculation("firefox"), "");
        compare(SearchQuery.calculation("7zip"), "");
        compare(SearchQuery.calculation("2048"), "");
        compare(SearchQuery.calculation("mp3 to wav"), "");
        compare(SearchQuery.calculation(""), "");
    }

    // A hung qalc is killed, so it exits and the next query is asked.
    function test_aHungQalcIsKilledAfterTheTimeout() {
        compare(SearchQuery.qalcCommand("2^2^2^2^2"),
            ["timeout", "-k", "1", "3", "qalc", "-t", "2^2^2^2^2"]);
    }

    function test_aQalcKilledForTakingTooLongGivesNoAnswer() {
        compare(SearchQuery.answer(["partial"], 124), "");
        compare(SearchQuery.answer([], 137), "");
    }
}
