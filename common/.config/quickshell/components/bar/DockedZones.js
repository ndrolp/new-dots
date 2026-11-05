.pragma library

// How far a zone of the docked bar grows for the attached popup hanging from
// it. The popup needs bar beside it all the way out to the end of its curved
// joins, plus clearance so they don't run into the zone's rounded corners.

// Takes the zone's { start, end } along the bar, the popup window's { start, end }
// or null, and the clearance. Returns how far each end grows, { start, end }.
function growth(zone, popup, clearance) {
    if (!popup)
        return { start: 0, end: 0 };

    return {
        start: Math.max(0, zone.start - (popup.start - clearance)),
        end: Math.max(0, popup.end + clearance - zone.end)
    };
}
