.pragma library
.import "../StatusText.js" as StatusText

// The capsule glance (capsule bar style only): the row of glance cards a
// capsule shows under its expanded row, past its workspace pills. Pure, no
// Quickshell: Quickshell objects are read only through their plain
// properties, so tests pass plain objects in their place.
// - cards(status, states): which cards show, in order, and what each says.
// - shown(capsule): whether the glance shows.
// - leavingElements(cards): the bar elements that leave the expanded row
//   while their card shows.

// Each card's look from what there is, `status`, by card id, in the order
// the cards stand left to right; a card with nothing to show gives null and
// isn't there.
const cardLooks = [
    { id: "media", element: "media", popup: "media", look: mediaLook },
    { id: "battery", element: "battery", popup: "battery", look: batteryLook },
    { id: "network", element: "network", popup: "network", look: networkLook }
];

// A time in seconds as hours and minutes, "3 h 20 m", or "45 m" under an
// hour. Part minutes are dropped.
function hoursAndMinutes(seconds) {
    const minutes = Math.floor(Math.max(0, seconds) / 60);
    const hours = Math.floor(minutes / 60);
    return hours > 0 ? hours + " h " + minutes % 60 + " m" : minutes + " m";
}

// The media card, from the Mpris player the Media element follows (`player`,
// null without one) as { trackTitle, trackArtist, trackArtUrl, identity,
// isPlaying }: its cover (`art`), the title over the artist, the player's
// name with no title, and whether it plays, for its play/pause button. No
// ring: the cover takes its place. None without a player.
function mediaLook(status) {
    const player = status.player;
    if (!player)
        return null;
    return {
        icon: "󰎈",
        ring: 0,
        title: player.trackTitle || player.identity || "",
        text: player.trackArtist || "",
        art: player.trackArtUrl || "",
        playing: player.isPlaying === true
    };
}

// The battery card, from UPower's display device (`battery`, null without
// one) and its UPowerDeviceState (`states`): a ring with the level, the
// percentage, and "Charging", the time left or "Full" ("On battery" while
// UPower doesn't know the time left). None without a battery.
function batteryLook(status, states) {
    const battery = status.battery;
    if (!battery || battery.isPresent === false)
        return null;

    const charging = battery.state === states.Charging || battery.state === states.PendingCharge;
    const text = charging ? "Charging"
        : battery.state === states.FullyCharged ? "Full"
        : battery.timeToEmpty > 0 ? hoursAndMinutes(battery.timeToEmpty) + " left"
        : "On battery";
    return {
        icon: StatusText.batteryIcon(battery, states),
        ring: battery.percentage,
        title: Math.round(battery.percentage * 100) + "%",
        text: text
    };
}

// The Wi-Fi card, from the network devices, `networks`, as
// { connected, wifi, signalStrength, name }, the signal strength (0 to 1)
// and name of a Wi-Fi device's connected network: the first connected one
// decides it. A ring with the signal and the network's name, full and
// "Ethernet" for a wired connection, or empty and "Offline" with none.
function networkLook(status) {
    const devices = status.networks || [];
    const device = devices.find(candidate => candidate.connected);
    const icon = StatusText.networkIcon(devices);
    if (!device)
        return { icon: icon, ring: 0, title: "Offline", text: "" };
    if (!device.wifi)
        return { icon: icon, ring: 1, title: "Ethernet", text: "" };
    return { icon: icon, ring: device.signalStrength || 0, title: device.name || "Wi-Fi", text: "" };
}

// The glance cards, left to right, from what there is, `status`:
// { player, battery, networks } (see mediaLook, batteryLook and
// networkLook), and UPower's UPowerDeviceState, `states`, which plain JS
// can't see on its own. Each is { id, element, popup, icon, ring, title,
// text }: the bar element it stands for and the popup a click on it opens,
// inside the capsule; an icon, a ring from 0 to 1, a title and a line of
// text under it ("" for none). The media card adds { art, playing }.
function cards(status, states) {
    return cardLooks.map(card => {
        const look = card.look(status || {}, states);
        return look ? Object.assign({ id: card.id, element: card.element, popup: card.popup }, look) : null;
    }).filter(card => card !== null);
}

// Whether the glance shows: under the expanded row only, from hovering or
// SUPER+I, so not at rest nor for a change event (`view`, as
// CapsuleRouting.rowView gives it), not while a popup is inside the capsule
// (`popupInside`), and only with `cards` to show. Takes
// { view, popupInside, cards }.
function shown(capsule) {
    return capsule.view === "expanded" && capsule.popupInside !== true
        && (capsule.cards || []).length > 0;
}

// The bar elements that leave the expanded row while the glance is `shown`:
// those its `cards` stand for, as ids; none without the glance.
function leavingElements(cards, shown) {
    return shown ? cards.map(card => card.element) : [];
}
