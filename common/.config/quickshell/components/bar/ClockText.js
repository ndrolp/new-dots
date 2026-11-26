.pragma library
.import "CapsuleLook.js" as CapsuleLook

// What the clock bar element shows (Clock.qml): the time, and in a capsule
// that looks expanded (CapsuleLook.looksExpanded) the date before it. Pure,
// no Quickshell.

// The day and month names the clock's date takes, in English like the rest
// of the shell, whatever the system locale.
const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function twoDigits(number) {
    return (number < 10 ? "0" : "") + number;
}

// What the clock shows at `date` on `bar`, as CapsuleLook.looksExpanded takes
// it: { date, time }. The time is "HH:mm"; the date, drawn dimmer before it, is
// "Thu 26 Nov · " while the capsule looks expanded, and empty otherwise.
function clockText(bar, date) {
    const time = twoDigits(date.getHours()) + ":" + twoDigits(date.getMinutes());
    if (!CapsuleLook.looksExpanded(bar))
        return { date: "", time: time };
    const day = days[date.getDay()] + " " + date.getDate() + " " + months[date.getMonth()];
    return { date: day + " · ", time: time };
}
