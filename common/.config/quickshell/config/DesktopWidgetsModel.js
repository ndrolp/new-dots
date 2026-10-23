.pragma library

// Desktop widgets model: pure logic over monitors.json display settings, no
// Quickshell. Desktop widgets are configured per monitor, outside the bar
// profiles (see docs/adr/0001).

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Desktop widgets: configured per monitor in monitors.json under
// displaySettings[monitor].desktopWidgets (the "default" entry is the template
// for monitors without their own entry).

const desktopWidgetNames = ["media", "system", "calendar", "network", "weather"];

const defaultDesktopWidgets = {
    order: ["media", "system", "calendar", "network", "weather"],
    backgroundClock: {
        enabled: true, position: "center", size: 96, opacity: 100,
        dateFormat: "full", calendarEnabled: false
    },
    media: { enabled: false, position: "bottom-left" },
    system: { enabled: false, position: "top-right" },
    calendar: { enabled: false, position: "top-left" },
    network: { enabled: false, position: "bottom-right" },
    weather: { enabled: false, position: "top-center", location: "Ourense, ES" }
};

// `widgets` completed with the built-in defaults, as a fresh object.
function completeDesktopWidgets(widgets) {
    const source = widgets || {};
    const complete = cloneValue(defaultDesktopWidgets);

    for (const key in complete) {
        if (source[key] === undefined)
            continue;
        if (Array.isArray(complete[key]))
            complete[key] = cloneValue(source[key]);
        else
            Object.assign(complete[key], cloneValue(source[key]));
    }

    return complete;
}

// The desktop widgets of a monitor, completed from the "default" entry.
function desktopWidgetsFor(displaySettings, monitorName) {
    const configured = displaySettings[monitorName];
    const defaults = displaySettings["default"];

    if (configured && configured.desktopWidgets)
        return completeDesktopWidgets(configured.desktopWidgets);

    return completeDesktopWidgets(defaults && defaults.desktopWidgets);
}

function withDesktopWidgets(displaySettings, monitorName, widgets) {
    const updated = Object.assign({}, displaySettings);
    const monitorSettings = Object.assign({}, displaySettings[monitorName]);
    monitorSettings.desktopWidgets = widgets;
    updated[monitorName] = monitorSettings;
    return updated;
}

// New displaySettings with `widget.key = value` on `monitorName` only.
function setDesktopWidgetSetting(displaySettings, monitorName, widget, key, value) {
    const widgets = desktopWidgetsFor(displaySettings, monitorName);
    widgets[widget][key] = cloneValue(value);
    return withDesktopWidgets(displaySettings, monitorName, widgets);
}

// The stack order of desktop widgets: known widgets once, missing ones last.
function desktopWidgetOrder(widgets) {
    const savedOrder = (widgets && widgets.order) || [];
    const order = [];

    for (let index = 0; index < savedOrder.length; index++) {
        const widget = savedOrder[index];
        if (desktopWidgetNames.indexOf(widget) !== -1 && order.indexOf(widget) === -1)
            order.push(widget);
    }

    for (let index = 0; index < desktopWidgetNames.length; index++) {
        if (order.indexOf(desktopWidgetNames[index]) === -1)
            order.push(desktopWidgetNames[index]);
    }

    return order;
}

// New displaySettings with `widget` moved by `offset` in the stack order of
// `monitorName`; unchanged when the move would leave the list.
function moveDesktopWidget(displaySettings, monitorName, widget, offset) {
    const widgets = desktopWidgetsFor(displaySettings, monitorName);
    const order = desktopWidgetOrder(widgets);
    const from = order.indexOf(widget);
    const to = from + offset;

    if (from < 0 || to < 0 || to >= order.length)
        return displaySettings;

    order.splice(from, 1);
    order.splice(to, 0, widget);
    widgets.order = order;
    return withDesktopWidgets(displaySettings, monitorName, widgets);
}
