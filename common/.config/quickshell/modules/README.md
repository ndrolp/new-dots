# Modules

The parts of the shell that `shell.qml` puts together. `shell.qml` creates the
config files and services once and hands them to each module; a module owns
its own state and its IPC handler, so adding a panel or an IPC call means
adding or editing one file here.

- `Feature.qml` is the base of every part that opens and closes: it owns
  `open`, and a part behind a plugin passes the plugin's switch as
  `available`, which keeps it closed and its IPC toggle idle while off.
  `switchTo(other)` closes one part and opens another, the way a control
  center tile opens the power menu. A module that opens other parts gets
  them as properties (`ControlCenter`, `QuickSettings`, `UnifiedSearch`).
- One module per panel: `ApplicationLauncher`, `AudioOutputSelector`,
  `ClipboardSelector`, `CommandLauncher`, `KeybindCheatsheet`,
  `PowerMenu`, `QuickSearch`, `QuickSettings`, `ScreenCapture` (the chooser),
  `Settings`, `ThemeSelector`, `UnifiedSearch`, `WallpaperSelector`,
  `WindowSwitcher` and `WorkspaceOverview`.
- `Bar.qml`: a bar on every monitor, and which popup is open
  (`OpenPopup.js`, tested). Its settings button opens the settings panel on
  that bar, and the bell opens the control center, its popup.
- `ControlCenter.qml`: not a `Feature`: the control center is the bell's
  popup. It holds the `control-center` IPC call (opens it expanded) and opens
  the panels its tiles ask for, closing it.
- `Notifications.qml`: the notification server, popups and sound, and the
  `notifications` IPC call (opens the control center collapsed).
- `BarProfiles.qml`: the default bar profile for new monitors and the
  `bar-profiles` IPC calls.
- `KeepAwake.qml`: the `keep-awake` IPC call the keybind runs, which toggles
  keep-awake and shows the OSD.
- `Osd.qml`, `Lock.qml` (the one lock screen and the `lock` IPC call) and
  `LowBattery.qml`.

These files import Quickshell, so they can't be loaded under the tests; what
they decide that is more than wiring lives in plain JS.
