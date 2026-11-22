import QtQuick
import QtTest
import "../components/bar"
import "../components/panels/OsdChange.js" as OsdChange
import "../config/Motion.js" as Motion

// A change as the capsule shows it: volume and brightness as a wide fill bar
// whose icon bounces on each change, battery and Bluetooth as a glance card
// with a small level ring.
TestCase {
    name: "CapsuleChangeView"
    width: 400
    height: 100
    visible: true
    when: windowShown

    Component {
        id: viewComponent

        CapsuleChangeView {
            theme: ({
                blue: "#0000ff",
                yellow: "#ffff00",
                accent: "#ff00ff",
                text: "#ffffff",
                textMuted: "#808080",
                background: "#000000",
                backgroundSecondary: "#202020"
            })
        }
    }

    function view(change, reduceMotion) {
        return createTemporaryObject(viewComponent, this, {
            change: change,
            appearance: { textSize: 13, motion: Motion.motion(reduceMotion === true) }
        });
    }

    // Volume is a wide (about 200px) bar with its icon and percentage.
    function test_volumeIsAWideFillBar() {
        const shown = view(OsdChange.volume(0.5, false));

        compare(shown.look.card, "level");
        verify(shown.implicitWidth > 200);
        verify(shown.implicitWidth < 320);
    }

    // Battery and Bluetooth are a glance card: narrower than the fill bar,
    // with a ring when there is a battery level.
    function test_bluetoothIsAGlanceCardWithARing() {
        const shown = view(OsdChange.bluetooth({ deviceName: "Buds", connected: true,
            batteryAvailable: true, battery: 0.6 }));

        compare(shown.look.card, "glance");
        compare(shown.ringShown, true);
    }

    function test_aGlanceCardWithoutABatteryHasNoRing() {
        const shown = view(OsdChange.bluetooth({ deviceName: "Keys", connected: true,
            batteryAvailable: false, battery: 0 }));

        compare(shown.ringShown, false);
    }

    // Each volume or brightness change bounces the icon slightly and it
    // settles back.
    function test_eachLevelChangeBouncesTheIcon() {
        const shown = view(OsdChange.volume(0.5, false));

        shown.change = OsdChange.volume(0.55, false);
        tryVerify(() => shown.iconScale > 1.05, 300);
        tryCompare(shown, "iconScale", 1, 1000);
    }

    // With reduce motion the icon doesn't bounce.
    function test_reduceMotionKeepsTheIconStill() {
        const shown = view(OsdChange.volume(0.5, false), true);

        shown.change = OsdChange.volume(0.55, false);
        wait(50);
        compare(shown.iconScale, 1);
    }
}
