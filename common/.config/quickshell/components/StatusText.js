.pragma library

// What the popups and the bar elements show for the media position, audio
// outputs, Wi-Fi, the battery and the network connection: pure logic, no
// Quickshell. Quickshell objects are read only through their plain
// properties, so tests pass plain objects in their place.

// A media position or length in seconds, as "m:ss".
function duration(seconds) {
    const totalSeconds = Math.max(0, Math.floor(seconds));
    const minutes = Math.floor(totalSeconds / 60);
    const remainingSeconds = totalSeconds % 60;
    return minutes + ":" + (remainingSeconds < 10 ? "0" : "") + remainingSeconds;
}

// The icon of an audio output (a Pipewire sink), guessed from its description.
function audioOutputIcon(output) {
    const description = String(output.description || "").toLowerCase();

    if (description.includes("headphone") || description.includes("headset"))
        return "󰋋";
    if (description.includes("hdmi") || description.includes("displayport"))
        return "󰍹";
    if (description.includes("bluetooth"))
        return "󰂯";
    return "󰓃";
}

// The icon of a Wi-Fi network, by its signal strength (0 to 100).
function wifiIcon(network) {
    if (network.signalStrength >= 75)
        return "󰤨";
    if (network.signalStrength >= 50)
        return "󰤥";
    if (network.signalStrength >= 25)
        return "󰤢";
    return "󰤟";
}

// The name of the network that is connected, or "" when none is.
function connectedNetworkName(networks) {
    for (let index = 0; index < networks.length; index++) {
        if (networks[index].connected)
            return networks[index].name;
    }

    return "";
}

// The battery is UPower's display device, or null without one. `states` is
// UPower's UPowerDeviceState, which plain JS can't see on its own.
function batteryIcon(battery, states) {
    if (!battery)
        return "󰂑";
    if (battery.state === states.Charging || battery.state === states.PendingCharge)
        return "󰂄";
    if (battery.percentage <= 0.15)
        return "󰂃";
    if (battery.percentage <= 0.4)
        return "󰁻";
    if (battery.percentage <= 0.7)
        return "󰁾";
    return "󰁹";
}

function batteryStateLabel(battery, states) {
    if (!battery)
        return "Battery unavailable";
    if (battery.state === states.Charging)
        return "Charging";
    if (battery.state === states.FullyCharged)
        return "Fully charged";
    if (battery.state === states.PendingCharge)
        return "Waiting to charge";
    if (battery.state === states.PendingDischarge)
        return "Waiting to discharge";
    return "Discharging";
}

// The network bar element's icon. `devices` are the network devices as
// `{ connected, wifi }`; the first connected one decides it.
function networkIcon(devices) {
    for (let index = 0; index < devices.length; index++) {
        if (devices[index].connected)
            return devices[index].wifi ? "󰤨" : "󰈀";
    }

    return "󰤭";
}
