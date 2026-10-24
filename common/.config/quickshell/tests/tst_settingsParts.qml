import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The parts every section of the settings panel is built from. They share the
// popups' minimal look (transparent, hairline borders, accent for focus and
// choice, only the section title bold), a little larger for a big window.
// Pointer events don't reach items under qmltestrunner offscreen, so taps and
// hover are checked in the renders instead; typing is checked with key events.
TestCase {
    name: "SettingsParts"
    width: 600
    height: 400
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
    }

    Component {
        id: input

        Panels.SettingsInput {
            width: 200
        }
    }

    Component {
        id: heading

        Panels.SettingsHeading {
            text: "Size & spacing"
        }
    }

    Component {
        id: label

        Panels.SettingsLabel {
            text: "Bar height"
        }
    }

    Component {
        id: hint

        Panels.SettingsHint {
            text: "Fills in the sizes below"
        }
    }

    Component {
        id: switchRow

        Panels.SettingsSwitchRow {
            width: 260
            label: "Transparent bar"
        }
    }

    // The text item showing `text` inside `item`.
    function textOf(item, text) {
        if (item.text === text)
            return item;
        for (let i = 0; i < item.children.length; i++) {
            const found = textOf(item.children[i], text);
            if (found)
                return found;
        }
        return null;
    }

    function make(component, properties) {
        return createTemporaryObject(component, this, Object.assign({ appearance: barAppearance }, properties || {}));
    }

    function test_aFieldIsTransparentWithAHairlineBorder() {
        const item = make(input);

        compare(item.height, 32);
        verify(!item.font.bold);
        compare(item.font.family, theme.fontFamily);
        compare(item.background.color, Qt.rgba(0, 0, 0, 0));
        compare(item.background.border.color, theme.border);
        compare(item.background.border.width, 1);
    }

    function test_aFocusedFieldHasAnAccentBorder() {
        const item = make(input);

        item.forceActiveFocus();
        compare(item.background.border.color, theme.accent);
    }

    // Group headings are small, muted and uppercase; setting labels are in
    // the normal text color; hints and values are muted. None is bold.
    function test_aGroupHeadingIsSmallMutedUppercase() {
        const item = make(heading);

        compare(item.font.capitalization, Font.AllUppercase);
        compare(item.font.pixelSize, 11);
        compare(item.color, theme.textMuted);
        verify(!item.font.bold);
    }

    function test_aSettingLabelIsRegularInTheNormalTextColor() {
        const item = make(label);

        compare(item.font.capitalization, Font.MixedCase);
        compare(item.font.pixelSize, 13);
        compare(item.color, theme.text);
        verify(!item.font.bold);
        compare(item.font.family, theme.fontFamily);
    }

    function test_aHintIsMutedAndSlightlySmaller() {
        const item = make(hint);

        compare(item.font.pixelSize, 12);
        compare(item.color, theme.textMuted);
        verify(!item.font.bold);
    }

    // A switch row is transparent until hovered, its label on the left and a
    // hairline pill switch on the right.
    function test_aSwitchRowAtRestIsTransparentWithItsLabelAndAnOutlinedSwitch() {
        const item = make(switchRow);
        const rowLabel = textOf(item, "Transparent bar");

        compare(item.color, Qt.rgba(0, 0, 0, 0));
        compare(item.height, 40);
        compare(rowLabel.color, theme.text);
        verify(!rowLabel.font.bold);
        compare(item.switchItem.color, Qt.rgba(0, 0, 0, 0));
        compare(item.switchItem.border.color, theme.border);
        verify(item.switchItem.x > rowLabel.x + rowLabel.width);
    }

    function test_aCheckedSwitchRowFillsItsSwitchWithTheAccent() {
        const item = make(switchRow, { checked: true });

        tryCompare(item.switchItem, "color", theme.accent, 500);
    }
}
