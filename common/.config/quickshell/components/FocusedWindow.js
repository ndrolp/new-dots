.pragma library

// The focused window as the bar elements that follow it (CurrentApp, the
// app menu) see it. Pure, no Quickshell: they pass Hyprland's objects in.

// Hyprland's active window while it is on the focused workspace, or null.
function focusedWindow(activeToplevel, focusedWorkspace) {
    return activeToplevel && activeToplevel.workspace && focusedWorkspace
        && activeToplevel.workspace.id === focusedWorkspace.id ? activeToplevel : null;
}

// Whether `monitor` (a bar's Hyprland monitor) holds the focused workspace:
// those elements show only on that monitor's bar.
function onFocusedMonitor(monitor, focusedWorkspace) {
    return !!monitor && !!focusedWorkspace && !!focusedWorkspace.monitor
        && focusedWorkspace.monitor.name === monitor.name;
}
