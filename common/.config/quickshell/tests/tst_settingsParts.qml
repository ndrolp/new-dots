import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config

// The parts every section of the settings panel is built from. They share the
// popups' minimal look (transparent, hairline borders, accent for focus and
// choice, only the section title bold), a little larger for a big window.
// Pointer events don't reach items under qmltestrunner offscreen, so taps are
// checked through the signals the parts expose, and typing with key events.
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
}
