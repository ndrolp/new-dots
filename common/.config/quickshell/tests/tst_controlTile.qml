import QtQuick
import QtTest
import "../components/panels" as Panels
import "../config" as Config
import "../config/Motion.js" as Motion

// A tile of the control center: a switch (on or off) or an action with a
// colored icon and a label. Pointer events don't reach items under qmltestrunner offscreen, so
// hover and taps aren't checked here.
TestCase {
    name: "ControlTile"
    width: 400
    height: 400
    visible: true
    when: windowShown

    Config.Theme {
        id: theme
    }

    QtObject {
        id: barAppearance

        property int radius: 12
        property int textSize: 13
        readonly property var motion: Motion.motion(true)
    }

    Component {
        id: tile

        Panels.ControlTile {
            appearance: barAppearance
            width: 120
            label: "Wi-Fi"
            icon: "󰤨"
            accentColor: theme.purple
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

    function make(properties) {
        return createTemporaryObject(tile, this, properties || {});
    }

    function test_anActiveTileShowsItsIconInItsColorAndItsLabelInText() {
        const item = make({ active: true });

        compare(textOf(item, "󰤨").color, theme.purple);
        compare(textOf(item, "Wi-Fi").color, theme.text);
    }

    function test_anInactiveTileIsMuted() {
        const item = make();

        compare(textOf(item, "󰤨").color, theme.textMuted);
        compare(textOf(item, "Wi-Fi").color, theme.textMuted);
    }

    function test_aTileTakesItsNewStateWhenItChanges() {
        const item = make();

        item.active = true;
        compare(textOf(item, "󰤨").color, theme.purple);
        item.active = false;
        compare(textOf(item, "󰤨").color, theme.textMuted);
    }

    // A tile is a card of the bar radius: a faint fill and a subtle border.
    function test_aTileIsABorderedCardOfTheBarRadius() {
        const item = make();

        compare(item.height, 64);
        compare(item.radius, 12);
        compare(item.color, theme.backgroundSecondary);
        compare(item.border.width, 1);
        compare(item.border.color, Qt.rgba(theme.border.r, theme.border.g, theme.border.b, 0.5));
    }

    function test_anActiveTileIsTintedWithItsColor() {
        const item = make({ active: true });

        compare(item.color, Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.15));
        compare(item.border.color, Qt.rgba(theme.purple.r, theme.purple.g, theme.purple.b, 0.35));
    }

    // The icon sits above the label, and a long label stays inside the tile.
    function test_theIconSitsAboveItsLabelAndALongLabelIsElided() {
        const item = make({ label: "A label far too long for any tile" });
        const icon = textOf(item, "󰤨");
        const label = textOf(item, "A label far too long for any tile");

        verify(icon.mapToItem(item, 0, 0).y < label.mapToItem(item, 0, 0).y);
        verify(label.width <= item.width);
        compare(label.elide, Text.ElideRight);
    }

    function test_anIconOnlyTileIsShorter() {
        compare(make({ labelShown: false }).height, 44);
    }

    function test_anEnabledTileIsOpaqueAndInteractive() {
        const item = make();

        compare(item.opacity, 1);
        verify(item.interactive);
    }

    // A tile whose device is missing (no Bluetooth adapter, no microphone) is
    // faded and doesn't react.
    function test_aDisabledTileIsFadedAndNotInteractive() {
        const item = make({ controlEnabled: false });

        compare(item.opacity, 0.45);
        verify(!item.interactive);
    }

    // The collapsed control center's tile row shows icons only.
    function test_aTileCanShowItsIconAlone() {
        const item = make({ labelShown: false });

        verify(textOf(item, "󰤨").visible);
        verify(!textOf(item, "Wi-Fi").visible);
    }

    function test_aDisabledTileCanStillShowItsState() {
        const item = make({ controlEnabled: false, active: true });

        compare(textOf(item, "󰤨").color, theme.purple);
    }
}
