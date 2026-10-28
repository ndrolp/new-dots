# Modules

The parts of the shell that `shell.qml` puts together. `shell.qml` creates the
config files and services once and hands them to each module; a module owns
its own state and its IPC handler, so adding a panel or an IPC call means
adding or editing one file here.

- `Feature.qml` is the base of every part that opens and closes: it owns
  `open`, and a part behind a plugin passes the plugin's switch as
  `available`, which keeps it closed and its IPC toggle idle while off.
  `switchTo(other)` closes one part and opens another, the way a control
  center button opens the power menu. A module that opens other parts gets
  them as properties (`ControlCenter`, `QuickSettings`, `UnifiedSearch`).
- One module per panel: `ApplicationLauncher`, `AudioSinkSelector`,
  `ClipboardSelector`, `CommandLauncher`, `ControlCenter`, `KeybindCheatsheet`,
  `PowerMenu`, `QuickSearch`, `QuickSettings`, `ScreenCapture` (the chooser),
  `Settings`, `ThemeSelector`, `UnifiedSearch`, `WallpaperSelector`,
  `WindowSwitcher` and `WorkspaceOverview`.
- `Bar.qml`: a bar on every monitor, and which popup is open
  (`OpenPopup.js`, tested). Its settings and notifications buttons open those
  panels on that bar.
- `Notifications.qml`: the notification server, popups, sound and panel.
- `BarProfiles.qml`: the default bar profile for new monitors and the
  `bar-profiles` IPC calls.
- `Osd.qml`, `Lock.qml` (the one lock screen and the `lock` IPC call) and
  `LowBattery.qml`.

These files import Quickshell, so they can't be loaded under the tests; what
they decide that is more than wiring lives in plain JS.
