import QtQuick
import "." as Panels

// A choice between the connected monitors: a segmented choice naming each by
// its short name (its model) with an icon for how it stands, so the options
// don't elide. The value is the monitor's description, which settings are
// stored under. When the chosen monitor isn't connected, or none is chosen
// yet, it asks for the first connected one.
Panels.SettingsChoice {
    id: choice

    // Each display is { description, name, portrait }; `name` may be empty.
    property var displays: []

    function chooseConnected() {
        if (!displays.some(display => display.description === value))
            chosen(displays.length > 0 ? displays[0].description : "");
    }

    options: displays.map(display => ({
        label: (display.portrait ? "󰍹 " : "󰍺 ") + (display.name || display.description),
        value: display.description
    }))

    Component.onCompleted: chooseConnected()
    onDisplaysChanged: chooseConnected()
}
