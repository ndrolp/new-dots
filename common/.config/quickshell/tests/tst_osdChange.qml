import QtQuick
import QtTest
import "../components/panels/OsdChange.js" as OsdChange
import "../services/KeepAwakeState.js" as KeepAwakeState

// The six changes the OSD shows, and the focused monitor's capsule instead of
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
}
