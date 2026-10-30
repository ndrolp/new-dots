import QtQuick
import QtTest
import "../config" as Config
import "../config/ColorschemeColors.js" as ColorschemeColors

// The theme's 16 colours come from the active colorscheme's colours file;
// when that file is missing or broken the shell keeps everforestdark's.
TestCase {
    name: "ColorschemeColors"

    Config.Theme {
        id: theme
    }

    function colorschemeFile(name) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("../../../../colorschemes/" + name + "/quickshell/colors.json"), false);
        request.send(null);
        return request.responseText;
    }

    function test_aColorschemesFileGivesItsColours() {
        const colours = ColorschemeColors.fromJson(colorschemeFile("nord"));

        compare(colours.background, "#2e3440");
        compare(colours.accent, "#88c0d0");
        compare(colours.textDisabled, "#616e88");
    }

    function test_aBrokenFileGivesEverforestdarksColours() {
        compare(ColorschemeColors.fromJson("{ not json"), JSON.parse(colorschemeFile("everforestdark")));
    }

    function test_aMissingFileGivesEverforestdarksColours() {
        compare(ColorschemeColors.fromJson(""), JSON.parse(colorschemeFile("everforestdark")));
    }

    function test_aFileMissingAColourGivesEverforestdarksColours() {
        const colours = JSON.parse(colorschemeFile("nord"));
        delete colours.border;

        compare(ColorschemeColors.fromJson(JSON.stringify(colours)), JSON.parse(colorschemeFile("everforestdark")));
    }

    function test_aFileWithAValueThatIsNotAColourGivesEverforestdarksColours() {
        const colours = JSON.parse(colorschemeFile("nord"));
        colours.accent = "green-ish";

        compare(ColorschemeColors.fromJson(JSON.stringify(colours)), JSON.parse(colorschemeFile("everforestdark")));
    }

    // Outside a running shell nothing reads the colours file, so the theme
    // has everforestdark's colours, plus its own font and radius.
    function test_theThemeOutsideTheShellHasEverforestdarksColoursAndItsFontAndRadius() {
        const everforestdark = JSON.parse(colorschemeFile("everforestdark"));

        for (const name in everforestdark)
            verify(Qt.colorEqual(theme[name], everforestdark[name]), name);
        compare(theme.fontFamily, "GeistMono Nerd Font Propo");
        compare(theme.radius, 8);
    }
}
