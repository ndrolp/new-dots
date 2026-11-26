.pragma library
.import "AudioOutputs.js" as AudioOutputs
.import "BluetoothDevices.js" as BluetoothDevices
.import "../../services/KeepAwakeState.js" as KeepAwakeState
.import "../StatusText.js" as StatusText
.import "../Clamp.js" as Clamp

// The changes the OSD shows (volume, brightness, Caps Lock, audio output,
// bar profile, keep-awake, Do Not Disturb, Bluetooth connections and power),
// and what each shows: the OSD and the focused monitor's capsule, in its
// place, show the same. Pure, no Quickshell.

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
// "battery" or "low", percentage }, kept as its `power` kind.
function power(event) {
    return { kind: "power", power: event.kind, percentage: event.percentage };
}

// Do Not Disturb turned on or off.
function doNotDisturb(on) {
    return { kind: "doNotDisturb", on: on === true };
}

// A Bluetooth device connected or disconnected: a BluetoothDevice or anything
// with its naming fields, `connected`, `batteryAvailable` and `battery` (0 to 1).
function bluetooth(device) {
    return {
        kind: "bluetooth",
        name: BluetoothDevices.label(device),
        connected: device.connected === true,
        battery: device.connected && device.batteryAvailable ? Math.round(device.battery * 100) : null
    };
}

function bluetoothLabel(change) {
    if (!change.connected)
        return change.name + " · Disconnected";
    return change.name + " · Connected" + (change.battery !== null ? " · " + change.battery + "%" : "");
}

// The theme colour of a change's `tone` (see display), from `theme`
// (config/Theme.qml): "warning" is the colorscheme's red; muted for any
// other tone.
function toneColor(tone, theme) {
    switch (tone) {
    case "warning":
        return theme.red;
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

function powerLabel(change) {
    const name = change.power === "charging" ? "Charging" : change.power === "low" ? "Battery low" : "On battery";
    return name + " · " + Math.round(change.percentage * 100) + "%";
}

// A power change's icon is the battery bar element's: charging or not, at
// its charge, and low the low-battery warning StatusText keeps for 10% or
// less.
function powerIcon(change) {
    const low = change.power === "low";
    const battery = { percentage: low ? Math.min(change.percentage, 0.1) : change.percentage,
        state: change.power === "charging" ? "charging" : "discharging" };
    return StatusText.batteryIcon(battery, { Charging: "charging" });
}

// A power change's tone: charging the accent, low battery the warning, on
// battery muted.
function powerTone(power) {
    return power === "charging" ? "accent" : power === "low" ? "warning" : "muted";
}

function audioOutputIcon(type) {
    if (type.includes("headphone") || type.includes("headset"))
        return "󰋋";
    return type.includes("hdmi") || type.includes("displayport") ? "󰍹" : "󰓃";
}

// What a change shows: { icon, tone, label, level, highlighted, compact }.
// `tone` is the icon's theme colour ("blue", "yellow", "accent", "warning"
// or "muted"),
// `level` is 0 to 1 for volume and brightness and null otherwise,
// `highlighted` (Caps Lock, keep-awake or Do Not Disturb on, battery low) puts
// the icon on the accent, and `compact` ones show just their icon and label.
function display(change) {
    const level = Clamp.unit(change.level || 0);

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
    case "doNotDisturb":
        return { icon: change.on ? "󰂛" : "󰂚", tone: "muted",
            label: change.on ? "Do Not Disturb on" : "Do Not Disturb off",
            level: null, highlighted: change.on, compact: true };
    case "profile":
        return { icon: "󰘳", tone: "accent", label: change.name + " bar profile", level: null,
            highlighted: false, compact: false };
    case "bluetooth":
        return { icon: change.connected ? "󰂱" : "󰂲", tone: change.connected ? "blue" : "muted",
            label: bluetoothLabel(change), level: null, highlighted: false, compact: true };
    case "power":
        return { icon: powerIcon(change), tone: powerTone(change.power),
            label: powerLabel(change), level: null, highlighted: change.power === "low", compact: true };
    default:
        return { icon: KeepAwakeState.cup(change.on), tone: "muted", label: change.label,
            level: null, highlighted: change.on, compact: true };
    }
}

// The glyph a volume or brightness change shows in the capsule for its level:
// low under a third, medium under two thirds, high from there. Muted volume
// is the struck-through speaker, whatever its level.
function levelIcon(change) {
    const level = Clamp.unit(change.level || 0);
    const step = level < 1 / 3 ? 0 : level < 2 / 3 ? 1 : 2;
    if (change.kind === "brightness")
        return ["󰃞", "󰃟", "󰃠"][step];
    if (change.muted)
        return "󰖁";
    return ["󰕿", "󰖀", "󰕾"][step];
}

// What a change shows in the capsule, by `card`:
// - "level" (volume, brightness): { icon (levelIcon), tone, level, percent };
//   muted volume is an empty bar in the muted tone.
// - "ring" (battery, Bluetooth): { icon, tone, text, ring, highlighted }:
//   one line of text and `ring`, the battery level 0 to 1 for a small ring
//   (the device's own for Bluetooth), or null when there is none.
// - "row": any other change, shown as `display` gives it.
function capsuleLook(change) {
    switch (change.kind) {
    case "volume":
    case "brightness": {
        const shown = display(change);
        const muted = change.muted === true;
        return { card: "level", icon: levelIcon(change), tone: muted ? "muted" : shown.tone,
            level: shown.level, percent: Math.round(shown.level * 100) + "%" };
    }
    case "power":
    case "bluetooth": {
        const shown = display(change);
        const ring = change.kind === "power" ? change.percentage
            : change.connected && change.battery !== null ? change.battery / 100 : null;
        return { card: "ring", icon: shown.icon, tone: shown.tone, text: shown.label,
            ring: ring === null ? null : Clamp.unit(ring), highlighted: shown.highlighted };
    }
    default:
        return { card: "row" };
    }
}
