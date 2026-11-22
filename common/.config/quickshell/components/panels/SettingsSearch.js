.pragma library

.import "../../config/BarProfileModel.js" as BarProfileModel

// What a settings search finds. Pure, no Quickshell.

// The settings of `section` (an entry of ConfigPanel's sections list) the
// search offers on a bar of `barStyle`: a Bar setting stored under a `key`
// only when that bar style uses it (BarProfileModel.barSettingShown).
function offeredSettings(section, barStyle) {
    return (section.settings || []).filter(setting => setting.key === undefined
        || BarProfileModel.barSettingShown(barStyle, setting.key));
}

// The sections `query` finds, in their order, each a copy of its entry
// whose `settings` are only the offered settings whose label holds the
// query. A section is found by its label and keywords, or by any of its
// settings. An empty query finds every section, with no settings listed.
function search(sections, query, barStyle) {
    const text = String(query).trim().toLowerCase();
    const found = [];

    for (const section of sections) {
        const settings = text === "" ? [] : offeredSettings(section, barStyle)
            .filter(setting => setting.label.toLowerCase().includes(text));
        const named = text === ""
            || (section.label + " " + section.keywords).toLowerCase().includes(text);

        if (named || settings.length > 0)
            found.push(Object.assign({}, section, { settings: settings }));
    }
    return found;
}

// Where Enter on the search goes: the first setting listed under the first
// section found, or that section when none is, as { section, setting } with
// `setting` "" for a section; null when nothing is found.
function firstMatch(found) {
    if (found.length === 0)
        return null;
    const first = found[0];
    return { section: first.section, setting: first.settings.length > 0 ? first.settings[0].label : "" };
}
