.pragma library
.import "AudioOutputs.js" as AudioOutputs
.import "../../services/KeepAwakeState.js" as KeepAwakeState
.import "../StatusText.js" as StatusText

// The changes the OSD shows (volume, brightness, Caps Lock, audio output,
// bar profile, keep-awake and power), and what each shows: the OSD and the focused
// monitor's capsule, in its place, show the same. Pure, no Quickshell.

// The volume, 0 to 1, as it is now; muted shows as none.
function volume(level, muted) {
    return { kind: "volume", level: muted ? 0 : level, muted: muted === true };
}

// The brightness, 0 to 1.
function brightness(level) {
    return { kind: "brightness", level: level };
}

// Caps Lock turned on or off.
function capsLock(on) {
    return { kind: "caps", on: on === true };
}

// The audio output chosen, a PwNode or anything with its naming fields.
function audioOutput(output) {
    const label = AudioOutputs.label(output);
    return {
        kind: "audioOutput",
        name: label !== "" ? label : "Audio output",
        // The icon goes by the description: it names the kind, the nickname doesn't.
        type: String((output && output.description) || "").toLowerCase()
    };
}

// The bar profile chosen, by name.
function barProfile(name) {
    return { kind: "profile", name: name };
}

// Keep-awake turned on, for `duration` minutes, or off.
function keepAwake(on, duration) {
    return { kind: "keepAwake", on: on === true, label: KeepAwakeState.osdLabel(on, duration) };
}

// A power change event (see services/PowerChange.js): { kind: "charging",
// "battery" or "low", percentage }. Its icon is the battery bar element's:
// charging or not, at its charge, and low the low-battery warning.
function power(event) {
    const charging = event.kind === "charging";
    const low = event.kind === "low";
    const name = charging ? "Charging" : low ? "Battery low" : "On battery";
    // Low shows the warning StatusText keeps for 10% or less.
    const battery = { percentage: low ? Math.min(event.percentage, 0.1) : event.percentage,
        state: charging ? "charging" : "discharging" };
    return {
        kind: "power",
        low: low,
        label: name + " · " + Math.round(event.percentage * 100) + "%",
        icon: StatusText.batteryIcon(battery, { Charging: "charging" }),
        tone: charging ? "accent" : "muted"
    };
}

// The theme colour of a change's `tone` (see display), from `theme`
// (config/Theme.qml): muted for any other tone.
function toneColor(tone, theme) {
    switch (tone) {
    case "blue":
        return theme.blue;
    case "yellow":
        return theme.yellow;
    case "accent":
        return theme.accent;
    default:
        return theme.textMuted;
    }
}

function audioOutputIcon(type) {
    if (type.includes("headphone") || type.includes("headset"))
        return "󰋋";
    return type.includes("hdmi") || type.includes("displayport") ? "󰍹" : "󰓃";
}

// What a change shows: { icon, tone, label, level, highlighted, compact }.
// `tone` is the icon's theme colour ("blue", "yellow", "accent" or "muted"),
// `level` is 0 to 1 for volume and brightness and null otherwise,
// `highlighted` (Caps Lock or keep-awake on, battery low) puts the icon on the accent, and
// `compact` ones show just their icon and label.
function display(change) {
    const level = Math.max(0, Math.min(1, change.level || 0));

    switch (change.kind) {
    case "volume":
        return { icon: change.muted ? "󰝟" : "󰕾", tone: "blue", label: "Volume", level: level,
            highlighted: false, compact: false };
    case "brightness":
        return { icon: "󰃠", tone: "yellow", label: "Brightness", level: level,
            highlighted: false, compact: false };
    case "caps":
        return { icon: "󰪛", tone: "muted", label: change.on ? "Caps Lock on" : "Caps Lock off",
            level: null, highlighted: change.on, compact: true };
    case "audioOutput":
        return { icon: audioOutputIcon(change.type), tone: "accent", label: change.name, level: null,
            highlighted: false, compact: false };
    case "profile":
        return { icon: "󰘳", tone: "accent", label: change.name + " bar profile", level: null,
            highlighted: false, compact: false };
    case "power":
        return { icon: change.icon, tone: change.tone, label: change.label, level: null,
            highlighted: change.low, compact: true };
    default:
        return { icon: KeepAwakeState.cup(change.on), tone: "muted", label: change.label,
            level: null, highlighted: change.on, compact: true };
    }
}
