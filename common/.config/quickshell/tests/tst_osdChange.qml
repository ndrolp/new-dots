import QtQuick
import QtTest
import "../components/panels/OsdChange.js" as OsdChange
import "../services/KeepAwakeState.js" as KeepAwakeState

// The changes the OSD shows, and the focused monitor's capsule instead of
// it: what each one shows, the same in both.
TestCase {
    name: "OsdChange"

    function shown(change) {
        const display = OsdChange.display(change);
        return {
            icon: display.icon,
            tone: display.tone,
            label: display.label,
            level: display.level,
            highlighted: display.highlighted,
            compact: display.compact
        };
    }

    function test_eachChangeShowsItsIconLabelAndLevel_data() {
        return [
            { tag: "volume", change: OsdChange.volume(0.42, false),
                shown: { icon: "󰕾", tone: "blue", label: "Volume", level: 0.42,
                    highlighted: false, compact: false } },
            { tag: "muted volume", change: OsdChange.volume(0.42, true),
                shown: { icon: "󰝟", tone: "blue", label: "Volume", level: 0,
                    highlighted: false, compact: false } },
            { tag: "brightness", change: OsdChange.brightness(0.7),
                shown: { icon: "󰃠", tone: "yellow", label: "Brightness", level: 0.7,
                    highlighted: false, compact: false } },
            { tag: "caps lock on", change: OsdChange.capsLock(true),
                shown: { icon: "󰪛", tone: "muted", label: "Caps Lock on", level: null,
                    highlighted: true, compact: true } },
            { tag: "caps lock off", change: OsdChange.capsLock(false),
                shown: { icon: "󰪛", tone: "muted", label: "Caps Lock off", level: null,
                    highlighted: false, compact: true } },
            { tag: "headphones", change: OsdChange.audioOutput({ nickname: "Buds",
                    description: "USB Headset" }),
                shown: { icon: "󰋋", tone: "accent", label: "Buds", level: null,
                    highlighted: false, compact: false } },
            { tag: "a monitor's speakers", change: OsdChange.audioOutput({
                    description: "HDMI / DisplayPort 1" }),
                shown: { icon: "󰍹", tone: "accent", label: "HDMI / DisplayPort 1", level: null,
                    highlighted: false, compact: false } },
            { tag: "an unnamed output", change: OsdChange.audioOutput({}),
                shown: { icon: "󰓃", tone: "accent", label: "Audio output", level: null,
                    highlighted: false, compact: false } },
            { tag: "bar profile", change: OsdChange.barProfile("work"),
                shown: { icon: "󰘳", tone: "accent", label: "work bar profile", level: null,
                    highlighted: false, compact: false } },
            { tag: "keep-awake on for an hour", change: OsdChange.keepAwake(true, 60),
                shown: { icon: KeepAwakeState.cup(true), tone: "muted", label: "Keep-awake on · 1 h",
                    level: null, highlighted: true, compact: true } },
            { tag: "keep-awake off", change: OsdChange.keepAwake(false, 60),
                shown: { icon: KeepAwakeState.cup(false), tone: "muted", label: "Keep-awake off",
                    level: null, highlighted: false, compact: true } },
            { tag: "do not disturb on", change: OsdChange.doNotDisturb(true),
                shown: { icon: "󰂛", tone: "muted", label: "Do Not Disturb on", level: null,
                    highlighted: true, compact: true } },
            { tag: "do not disturb off", change: OsdChange.doNotDisturb(false),
                shown: { icon: "󰂚", tone: "muted", label: "Do Not Disturb off", level: null,
                    highlighted: false, compact: true } },
            { tag: "bluetooth device connected with its battery",
                change: OsdChange.bluetooth({ deviceName: "WH-1000XM4", address: "AA:BB:CC:DD:EE:FF",
                    connected: true, batteryAvailable: true, battery: 0.8 }),
                shown: { icon: "󰂱", tone: "blue", label: "WH-1000XM4 · Connected · 80%",
                    level: null, highlighted: false, compact: true } },
            { tag: "bluetooth device connected without a battery",
                change: OsdChange.bluetooth({ deviceName: "MX Keys", address: "AA:BB:CC:DD:EE:01",
                    connected: true, batteryAvailable: false, battery: 0 }),
                shown: { icon: "󰂱", tone: "blue", label: "MX Keys · Connected",
                    level: null, highlighted: false, compact: true } },
            { tag: "bluetooth device disconnected",
                change: OsdChange.bluetooth({ deviceName: "WH-1000XM4", address: "AA:BB:CC:DD:EE:FF",
                    connected: false, batteryAvailable: true, battery: 0.8 }),
                shown: { icon: "󰂲", tone: "muted", label: "WH-1000XM4 · Disconnected",
                    level: null, highlighted: false, compact: true } },
            { tag: "unnamed bluetooth device",
                change: OsdChange.bluetooth({ name: "AA:BB:CC:DD:EE:02", address: "AA:BB:CC:DD:EE:02",
                    connected: true }),
                shown: { icon: "󰂱", tone: "blue", label: "Unnamed device · Connected",
                    level: null, highlighted: false, compact: true } }
        ];
    }

    function test_eachChangeShowsItsIconLabelAndLevel(data) {
        compare(shown(data.change), data.shown);
    }

    // A chosen audio output is its own kind of change, as the glossary names it.
    function test_anAudioOutputChangeIsAnAudioOutput() {
        compare(OsdChange.audioOutput({ nickname: "Buds" }).kind, "audioOutput");
    }

    // A level past either end shows as the end.
    function test_aLevelStaysBetweenNoneAndFull() {
        compare(OsdChange.display(OsdChange.volume(1.3, false)).level, 1);
        compare(OsdChange.display(OsdChange.brightness(-0.2)).level, 0);
    }

    // In the capsule, volume and brightness show a glyph for their level:
    // low under a third, medium under two thirds, high from there; muted
    // volume the struck-through speaker, whatever its level.
    function test_inTheCapsuleTheIconFollowsTheLevel_data() {
        return [
            { tag: "silent volume", change: OsdChange.volume(0, false), icon: "󰕿" },
            { tag: "low volume", change: OsdChange.volume(0.3, false), icon: "󰕿" },
            { tag: "medium volume", change: OsdChange.volume(0.5, false), icon: "󰖀" },
            { tag: "high volume", change: OsdChange.volume(0.7, false), icon: "󰕾" },
            { tag: "full volume", change: OsdChange.volume(1, false), icon: "󰕾" },
            { tag: "muted volume", change: OsdChange.volume(0.9, true), icon: "󰖁" },
            { tag: "dim", change: OsdChange.brightness(0.1), icon: "󰃞" },
            { tag: "half bright", change: OsdChange.brightness(0.5), icon: "󰃟" },
            { tag: "bright", change: OsdChange.brightness(0.9), icon: "󰃠" }
        ];
    }

    function test_inTheCapsuleTheIconFollowsTheLevel(data) {
        compare(OsdChange.levelIcon(data.change), data.icon);
    }

    // In the capsule, volume and brightness are a fill bar with the icon and
    // percentage (muted, an empty grey one); battery and Bluetooth a ring
    // card: icon, one line and a small ring of the battery level, the
    // device's own for Bluetooth when it reports one; any other change the
    // OSD's row.
    function test_inTheCapsuleEachChangeShowsItsCard_data() {
        return [
            { tag: "volume", change: OsdChange.volume(0.42, false),
                look: { card: "level", icon: "󰖀", tone: "blue", level: 0.42, percent: "42%" } },
            { tag: "muted volume", change: OsdChange.volume(0.42, true),
                look: { card: "level", icon: "󰖁", tone: "muted", level: 0, percent: "0%" } },
            { tag: "brightness", change: OsdChange.brightness(0.8),
                look: { card: "level", icon: "󰃠", tone: "yellow", level: 0.8, percent: "80%" } },
            { tag: "charging", change: OsdChange.power({ kind: "charging", percentage: 0.55 }),
                look: { card: "ring", icon: String.fromCodePoint(0xF0089), tone: "accent", text: "Charging · 55%",
                    ring: 0.55, highlighted: false } },
            { tag: "battery low", change: OsdChange.power({ kind: "low", percentage: 0.08 }),
                look: { card: "ring", icon: "󰂃", tone: "warning", text: "Battery low · 8%",
                    ring: 0.08, highlighted: true } },
            { tag: "bluetooth with its battery",
                change: OsdChange.bluetooth({ deviceName: "WH-1000XM4", connected: true,
                    batteryAvailable: true, battery: 0.8 }),
                look: { card: "ring", icon: "󰂱", tone: "blue", text: "WH-1000XM4 · Connected · 80%",
                    ring: 0.8, highlighted: false } },
            { tag: "bluetooth without a battery",
                change: OsdChange.bluetooth({ deviceName: "MX Keys", connected: true,
                    batteryAvailable: false, battery: 0 }),
                look: { card: "ring", icon: "󰂱", tone: "blue", text: "MX Keys · Connected",
                    ring: null, highlighted: false } },
            { tag: "bluetooth disconnected",
                change: OsdChange.bluetooth({ deviceName: "WH-1000XM4", connected: false,
                    batteryAvailable: true, battery: 0.8 }),
                look: { card: "ring", icon: "󰂲", tone: "muted", text: "WH-1000XM4 · Disconnected",
                    ring: null, highlighted: false } },
            { tag: "caps lock", change: OsdChange.capsLock(true), look: { card: "row" } },
            { tag: "bar profile", change: OsdChange.barProfile("work"), look: { card: "row" } }
        ];
    }

    function test_inTheCapsuleEachChangeShowsItsCard(data) {
        compare(OsdChange.capsuleLook(data.change), data.look);
    }

    // Low battery warns in the colorscheme's red; charging keeps the accent
    // and on battery the muted tone.
    function test_aBatteryChangeTakesItsColour_data() {
        return [
            { tag: "low", kind: "low", colour: "red" },
            { tag: "charging", kind: "charging", colour: "accent" },
            { tag: "on battery", kind: "battery", colour: "textMuted" }
        ];
    }

    function test_aBatteryChangeTakesItsColour(data) {
        const theme = { red: "#ff0000", accent: "#00ff00", textMuted: "#888888", blue: "#0000ff",
            yellow: "#ffff00" };
        const look = OsdChange.capsuleLook(OsdChange.power({ kind: data.kind, percentage: 0.08 }));
        compare(OsdChange.toneColor(look.tone, theme), theme[data.colour]);
    }
}
