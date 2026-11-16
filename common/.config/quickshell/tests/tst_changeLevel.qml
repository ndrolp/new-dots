import QtQuick
import QtTest
import "../components/panels" as Panels
import "../components/panels/OsdChange.js" as OsdChange

// The parts the OSD and the capsule share to show a change: its tone's
// colour, and its level as a filled bar with its percent.
TestCase {
    name: "ChangeLevel"
    width: 300
    height: 100
    visible: true
    when: windowShown

    readonly property var theme: ({
        blue: "#0000ff",
        yellow: "#ffff00",
        accent: "#ff00ff",
        textMuted: "#808080",
        backgroundSecondary: "#000000"
    })

    function test_eachToneHasItsThemeColour_data() {
        return [
            { tag: "blue", tone: "blue", colour: "#0000ff" },
            { tag: "yellow", tone: "yellow", colour: "#ffff00" },
            { tag: "accent", tone: "accent", colour: "#ff00ff" },
            { tag: "muted", tone: "muted", colour: "#808080" },
            { tag: "no tone", tone: undefined, colour: "#808080" }
        ];
    }

    function test_eachToneHasItsThemeColour(data) {
        compare(OsdChange.toneColor(data.tone, theme), data.colour);
    }

    Component {
        id: levelComponent

        Panels.ChangeLevel {
            appearance: ({ textSize: 13 })
            theme: ({ backgroundSecondary: "#000000", textMuted: "#808080" })
            toneColor: "#0000ff"
            barWidth: 100
        }
    }

    function percentText(item) {
        for (let i = 0; i < item.children.length; i++)
            if (item.children[i].text !== undefined)
                return item.children[i].text;
        return null;
    }

    // The bar fills to the level in the tone's colour, and the percent says it.
    function test_theBarFillsToTheLevelAndThePercentSaysIt() {
        const level = createTemporaryObject(levelComponent, this, { level: 0.42 });

        compare(percentText(level), "42%");
        waitForRendering(level);
        const image = grabImage(level);
        const middle = level.children[0].y + 3;
        compare(image.pixel(40, middle), Qt.color("#0000ff"));
        compare(image.pixel(60, middle), Qt.color("#000000"));
    }

    // Stacked (the OSD), the percent goes under the bar; otherwise (the
    // capsule) beside it.
    function test_stackedThePercentGoesUnderTheBar() {
        const beside = createTemporaryObject(levelComponent, this, { level: 0.5 });
        const stacked = createTemporaryObject(levelComponent, this, { level: 0.5, stacked: true });

        verify(beside.implicitWidth > 100);
        verify(stacked.implicitWidth >= 100);
        verify(stacked.implicitHeight > beside.implicitHeight);
    }
}
