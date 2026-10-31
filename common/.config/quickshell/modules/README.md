# Modules

The parts of the shell that `shell.qml` puts together. `shell.qml` creates the
config files and services once and hands them to each module; a module owns
its own state and its IPC handler, so adding a panel or an IPC call means
adding or editing one file here.

- `Feature.qml` is the base of every part that opens and closes: it owns
  `open`, and a part behind a plugin passes the plugin's switch as
  `available`, which keeps it closed and its IPC toggle idle while off.
  `switchTo(other)` closes one part and opens another (`other.show()`), the
  way quick settings opens the settings panel; anything with `available`
  and `show()` can be switched to, the control center among them. The rule
  lives in `SwitchTo.js` (tested), which the control center's tiles use too.
  A module that opens other parts gets them as properties (`ControlCenter`,
  `QuickSettings`, `UnifiedSearch`).
- One module per panel: `ApplicationLauncher`, `AudioOutputSelector`,
  `ClipboardSelector`, `CommandLauncher`, `KeybindCheatsheet`,
  `PowerMenu`, `QuickSearch`, `QuickSettings`, `ScreenCapture` (the chooser),
  `Settings`, `ThemeSelector`, `UnifiedSearch`, `WallpaperSelector`,
  `WindowSwitcher` and `WorkspaceOverview`.
- `Bar.qml`: a bar on every monitor, and which popup is open
  (`OpenPopup.js`, tested). Its settings button opens the settings panel on
  that bar, and a bar element opens its popup (`barElementOpening` tells
  first). Other modules open and close popups through its `openPopup`,
  `bars()`, `focusedMonitor()` and `closePopup()`.
- `ControlCenter.qml`: not a `Feature`: the control center is the bell's
  popup. The module owns its state and is handed, as one object, through
  the bar to the popup and its controls: the services they show,
  `controlsEnabled` (its plugin) and `stage`. A tile that opens a panel calls
  `openPanel(name)` (names in `components/panels/ControlCenterNames.js`),
  which closes the control center and opens that panel in its place.
  Shortcuts (`toggle(stage)`, `OpenPopup.controlCenterShortcut`, tested):
  SUPER+N (`notifications` IPC) asks for collapsed, SUPER+C
  (`control-center` IPC) for expanded. Closed, or open on another bar, it
  opens at that stage on the focused bar; open at the other stage, it
  switches in place; open at that stage, it closes. With its plugin off
  both just open and close it. The bell always opens it collapsed and
  closes it at whatever stage. Switching it from inside (the handle, the
  audio output tile) updates `stage`, so the shortcuts know where it is.
- `Notifications.qml`: the notification server, toasts and sound, and the
  `notifications` IPC call (SUPER+N, the control center's collapsed
  shortcut).
- `BarProfiles.qml`: the default bar profile for new monitors and the
  `bar-profiles` IPC calls.
- `KeepAwake.qml`: the `keep-awake` IPC call the keybind runs, which toggles
  keep-awake and shows the OSD.
- `Osd.qml`, `Lock.qml` (the one lock screen and the `lock` IPC call) and
  `LowBattery.qml`.

These files import Quickshell, so they can't be loaded under the tests; what
they decide that is more than wiring lives in plain JS.
