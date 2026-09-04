# Services

Place shared system integrations here, such as audio, network, and battery services.

## Screen capture integration

`ScreenCapture.qml` detects `grim`, `slurp`, `wf-recorder`, and `wayshot` at runtime.
It saves captures to `$(xdg-user-dir PICTURES)/Screenshots`; the service only runs
fixed executable argument lists and passes the selected region directly from `slurp`.

The shell owner must add the following (the component must be instantiated once for
tool detection and IPC actions):

```qml
property bool screenCaptureOpen: false

Services.ScreenCapture {
    id: screenCapture
}

Panels.ScreenCapture {
    appearance: appearance
    screenCapture: screenCapture
    open: shell.screenCaptureOpen
    onCloseRequested: shell.screenCaptureOpen = false
}

IpcHandler {
    target: "screen-capture"

    function toggle() {
        shell.screenCaptureOpen = !shell.screenCaptureOpen;
    }
}
```

Replace the existing `SUPER + SHIFT + S` binding with:

```lua
hl.bind(win .. " + SHIFT + S",
    hl.dsp.exec_cmd("quickshell ipc --path ~/.config/quickshell call screen-capture toggle"))
```

The chooser supports `1`/`Enter` for a region screenshot, `2` for the focused
display, `3`/`4` for recordings when `wf-recorder` is installed, and `R` or
`Escape` to stop a recording.
