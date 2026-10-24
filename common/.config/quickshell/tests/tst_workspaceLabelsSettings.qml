import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The Workspace Labels section, built from the settings parts: the glyphs
// switch as a switch row and the labels for workspaces 1-20 as short hairline
// fields, several per line.
TestCase {
    name: "WorkspaceLabelsSettings"
    width: 800
    height: 800
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

    function fields(item) {
        return all(item, child => child instanceof TextInput && child.placeholderText !== undefined);
    }

    function switchRow(item, label) {
        return all(item, child => child.label === label && child.switchItem !== undefined)[0];
    }

    // A fake appearance stands in for the shell's and records what is saved.
    Component {
        id: page

        Item {
            property alias appearance: appearance
            property alias section: section

            width: 700

            QtObject {
                id: appearance

                property int radius: 12
                property int textSize: 13
                property var glyphs: ["", "", "", ""]
                property var saved: []

                function barElementOption(element, option) {
                    return option === "glyphs" ? glyphs.slice() : true;
                }

                function setBarElementOption(element, option, value) {
                    saved = saved.concat([[element, option, value]]);
                }
            }

            Panels.WorkspaceLabelsSettings {
                id: section

                appearance: appearance
            }
        }
    }

    function make() {
        const built = createTemporaryObject(page, this);
        return { appearance: built.appearance, item: built.section };
    }

    function test_twentyLabelFieldsSitSeveralPerLine() {
        const built = make();
        const labels = fields(built.item);

        compare(labels.length, 20);
        compare(labels[0].placeholderText, "1");
        compare(labels[1].placeholderText, "2");
        compare(labels[0].text, "");
        compare(labels[1].text, "");
        const first = labels[0].mapToItem(built.item, 0, 0);
        const second = labels[1].mapToItem(built.item, 0, 0);
        compare(first.y, second.y);
        verify(first.x < second.x);
        verify(labels[0].width < built.item.width / 2);
    }

    function test_labelFieldsHaveTheHairlineLook() {
        const built = make();
        const label = fields(built.item)[0];

        compare(label.background.color, Qt.rgba(0, 0, 0, 0));
        compare(label.background.border.color, theme.border);
    }

    function test_typingALabelStillSavesIt() {
        const built = make();
        const label = fields(built.item)[2];

        label.forceActiveFocus();
        keyClick("x");

        compare(built.appearance.saved, [["workspaces", "glyphs", ["", "", "x", ""]]]);
    }

    function test_theGlyphsSwitchIsATransparentSwitchRowThatSavesWhenToggled() {
        const built = make();
        const glyphs = switchRow(built.item, "Use workspace glyphs");

        verify(glyphs);
        compare(glyphs.color, Qt.rgba(0, 0, 0, 0));
        verify(glyphs.checked);

        glyphs.toggled();
        compare(built.appearance.saved, [["workspaces", "glyphsEnabled", false]]);
    }

    function test_noFilledCardsAndNothingBold() {
        const built = make();
        const bold = all(built.item, child => child.font !== undefined && child.font.bold);
        const filled = all(built.item, child => child instanceof Rectangle && child.radius > 0
            && child.color.a > 0 && child.height >= 32);

        compare(bold.length, 0);
        compare(filled.length, 0);
    }
}
