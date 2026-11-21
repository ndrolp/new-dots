.pragma library
.import "AudioOutputs.js" as AudioOutputs
.import "BluetoothDevices.js" as BluetoothDevices
.import "../../services/KeepAwakeState.js" as KeepAwakeState

// The changes the OSD shows (volume, brightness, Caps Lock, audio output,
// bar profile, keep-awake, Do Not Disturb and Bluetooth connections), and
// what each shows: the OSD and the focused monitor's capsule, in its place,
// show the same. Pure, no Quickshell.

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
// `highlighted` (Caps Lock, keep-awake or Do Not Disturb on) puts the icon on
// the accent, and `compact` ones show just their icon and label.
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
    default:
        return { icon: KeepAwakeState.cup(change.on), tone: "muted", label: change.label,
            level: null, highlighted: change.on, compact: true };
    }
}
