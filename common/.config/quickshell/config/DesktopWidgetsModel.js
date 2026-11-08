.pragma library

// Desktop widgets model: pure logic over monitors.json display settings, no
// Quickshell. Desktop widgets are configured per monitor, outside the bar
// profiles (see docs/adr/0001).

function cloneValue(value) {
    return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

// Desktop widgets: configured per monitor in monitors.json under
// displaySettings[monitor].desktopWidgets.

const desktopWidgetNames = ["media", "system", "calendar", "network", "weather", "cava"];

// The colors the Cava desktop widget's bars can take: white, or one of the
// theme's named colors, which follow the colorscheme.
const cavaColors = ["white", "accent", "blue", "green", "yellow", "orange", "red", "purple", "text"];

// How the Cava desktop widget shows the track progress: not at all, as a thin
// line under the bars, or by painting the bars in the progress color up to
// the played fraction.
const cavaProgressStyles = ["off", "line", "bars"];

// How far the desktop widgets keep from the edges of what the monitor's bar
// leaves free, in pixels; the background clock keeps a little more.
const defaultEdgePadding = 28;
const edgePaddingRange = { from: 0, to: 200 };

const defaultDesktopWidgets = {
    order: ["media", "system", "calendar", "network", "weather", "cava"],
    edgePadding: defaultEdgePadding,
    backgroundClock: {
        enabled: true, position: "center", size: 96, opacity: 100,
        dateFormat: "full", calendarEnabled: false
    },
    media: { enabled: false, position: "bottom-left" },
    system: { enabled: false, position: "top-right" },
    calendar: { enabled: false, position: "top-left" },
    network: { enabled: false, position: "bottom-right" },
    weather: { enabled: false, position: "top-center", location: "Ourense, ES" },
    // Just the bars, no card: `width` and `height` are the area they fill; the
    // progress line and the media info go below them (cavaExtraHeight).
    cava: {
        enabled: false, position: "bottom-center", width: 360, height: 80, barCount: 32,
        color: "white", shadow: true, mediaInfo: false, progress: "off", progressColor: "accent"
    }
};

// The Cava widget's media info: the cover is a square as tall as the title,
// artist and album together, so it grows with the shell's text size.
function cavaCoverSize(textSize) {
    return Math.round(textSize * 5.6);
}

const cavaLineGap = 8;
const cavaLineHeight = 3;
const cavaInfoGap = 10;

// What the Cava widget adds below its bars: the progress line when that is
// the progress style, and the media info when it is on. It doesn't depend on
// what plays, so the widget keeps its place in the stack.
function cavaExtraHeight(cava, textSize) {
    let height = 0;
    if (cava.progress === "line")
        height += cavaLineGap + cavaLineHeight;
    if (cava.mediaInfo)
        height += cavaInfoGap + cavaCoverSize(textSize);
    return height;
}

// `widgets` completed with the built-in defaults, as a fresh object.
function completeDesktopWidgets(widgets) {
    const source = widgets || {};
    const complete = cloneValue(defaultDesktopWidgets);

    for (const key in complete) {
        if (source[key] === undefined)
            continue;
        if (Array.isArray(complete[key]) || typeof complete[key] !== "object")
            complete[key] = cloneValue(source[key]);
        else
            Object.assign(complete[key], cloneValue(source[key]));
    }

    return complete;
}

// The desktop widgets of a monitor, completed with the built-in defaults.
function desktopWidgetsFor(displaySettings, monitorName) {
    const configured = (displaySettings || {})[monitorName];
    return completeDesktopWidgets(configured && configured.desktopWidgets);
}

function withDesktopWidgets(displaySettings, monitorName, widgets) {
    const updated = Object.assign({}, displaySettings);
    const monitorSettings = Object.assign({}, displaySettings[monitorName]);
    monitorSettings.desktopWidgets = widgets;
    updated[monitorName] = monitorSettings;
    return updated;
}

// New displaySettings with the edge padding of `monitorName` only set.
function setEdgePadding(displaySettings, monitorName, padding) {
    const widgets = desktopWidgetsFor(displaySettings, monitorName);
    widgets.edgePadding = Math.max(edgePaddingRange.from, Math.min(edgePaddingRange.to, Math.round(padding)));
    return withDesktopWidgets(displaySettings, monitorName, widgets);
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

// Where a desktop widget sits, as its row (top, center, bottom) and column
// (left, center, right). The stored position joins them, "top-left",
// "center-right"…, and is just "center" when both are.
function placementOf(position) {
    const parts = position === "center" ? ["center", "center"] : String(position).split("-");
    return { vertical: parts[0], horizontal: parts[1] };
}

// Where something of `size` sits in `area`, keeping `gaps` from the area's
// sides. `stack` is its place among what shares the position: its offset
// from the edge and the height of them all (see DesktopWidgets.qml).
function placedInArea(position, size, area, gaps, stack) {
    const placement = placementOf(position);
    const x = placement.horizontal === "left" ? gaps.side
        : placement.horizontal === "right" ? area.width - size.width - gaps.side
        : (area.width - size.width) / 2;
    const y = placement.vertical === "top" ? gaps.top + stack.offset
        : placement.vertical === "bottom" ? area.height - size.height - gaps.bottom - stack.offset
        : (area.height - stack.height) / 2 + stack.offset;

    return { x: x, y: y };
}

// The area is what the monitor's bar leaves free, the size of the windows of
// the desktop widgets, so the gaps don't depend on the bar. `padding` is the
// monitor's edge padding; the bottom keeps 8px more, and the background clock
// 20px more all round.
function cardPosition(position, size, area, stack, padding) {
    const edge = padding === undefined ? defaultEdgePadding : padding;
    return placedInArea(position, size, area, { top: edge, bottom: edge + 8, side: edge }, stack);
}

function clockPosition(position, size, area, padding) {
    const edge = (padding === undefined ? defaultEdgePadding : padding) + 20;
    return placedInArea(position, size, area, { top: edge, bottom: edge + 8, side: edge },
        { offset: 0, height: size.height });
}

// The stored position of a row and column (see placementOf).
function positionOf(vertical, horizontal) {
    return vertical === "center" && horizontal === "center" ? "center" : vertical + "-" + horizontal;
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
