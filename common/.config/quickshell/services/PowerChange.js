.pragma library

// The power change events, from UPower's display device: the charger plugged
// in ("charging") or out ("battery"), and the battery reaching 15% while
// discharging ("low"), at the low-battery notification's threshold
// (modules/LowBattery.qml) and re-armed like it. Pure, no Quickshell.

// The charge, 0 to 1, at or under which a discharging battery is low.
const lowThreshold = 0.15;

// What a reading of `battery` (UPower's display device, or null) says:
// { present: false } without a battery, else { present, plugged, discharging,
// percentage }. `plugged` is null when its state doesn't say (unknown, or
// waiting to discharge). `states` is UPower's UPowerDeviceState, which plain
// JS can't see on its own.
function reading(battery, states) {
    if (!battery || !battery.isPresent)
        return { present: false };

    let plugged = null;
    if (battery.state === states.Charging || battery.state === states.PendingCharge
            || battery.state === states.FullyCharged)
        plugged = true;
    else if (battery.state === states.Discharging || battery.state === states.Empty)
        plugged = false;

    return {
        present: true,
        plugged: plugged,
        discharging: battery.state === states.Discharging,
        percentage: battery.percentage
    };
}

// The next state after `reading` (see reading), from `state` (null before
// the first reading, or without a battery), and the event it makes:
// { kind: "charging" | "battery" | "low", percentage }, or null. The first
// reading is how it already was and makes none; reaching the threshold while
// discharging, unplugging included, makes "low" once, until it has been above
// it or plugged in again.
function next(state, reading) {
    if (!reading || !reading.present)
        return { state: null, event: null };
    if (reading.plugged === null)
        return { state: state, event: null };

    const low = reading.discharging && reading.percentage <= lowThreshold;
    const nextState = { plugged: reading.plugged, low: low };
    if (!state)
        return { state: nextState, event: null };

    let kind = null;
    if (low && !state.low)
        kind = "low";
    else if (reading.plugged !== state.plugged)
        kind = reading.plugged ? "charging" : "battery";

    return { state: nextState, event: kind ? { kind: kind, percentage: reading.percentage } : null };
}
