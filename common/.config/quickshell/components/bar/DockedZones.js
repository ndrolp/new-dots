.pragma library

// How far a zone of the docked bar grows for the attached popup hanging from
// it. The popup needs bar above it all the way out to the end of its curved
// joins, plus clearance so they don't run into the zone's rounded corners.

// Takes the zone's { left, right }, the popup window's { left, right } or null,
// and the clearance. Returns how far each side grows, { left, right }.
function growth(zone, popup, clearance) {
    if (!popup)
        return { left: 0, right: 0 };

    return {
        left: Math.max(0, zone.left - (popup.left - clearance)),
        right: Math.max(0, popup.right + clearance - zone.right)
    };
}
