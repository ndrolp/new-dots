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

    function test_aTileIsARowOfTheBarRadius() {
        const item = make();

        compare(item.height, 38);
        compare(item.radius, 12);
        compare(item.color, Qt.rgba(0, 0, 0, 0));
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
