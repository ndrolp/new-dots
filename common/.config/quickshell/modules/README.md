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
  A module that opens other parts gets them as properties (`AppMenu`,
  `ControlCenter`, `QuickSettings`, `UnifiedSearch`).
- One module per panel: `AndroidDevices` (the Android devices panel,
  SUPER+SHIFT+A, `android-devices toggle`, whose Android devices and pairing services read adb only
  while it's open), `ApplicationLauncher`, `AudioOutputSelector`,
  `ClipboardSelector`, `CommandLauncher`, `KeybindCheatsheet`,
  `PowerMenu`, `Printers` (the Printers panel, SUPER+SHIFT+P,
  `printers toggle`, which has the printers, discovered printers and
  scanners services look only while it's open), `QuickSearch`,
  `QuickSettings`, `QuickSwitch` (SUPER+P, `quick-switch press`, which
  moves down when it's open), `ScreenCapture` (the chooser), `Settings`,
  `ThemeSelector`, `UnifiedSearch`, `WallpaperSelector`, `WebApps` (the web
  app maker, SUPER+SHIFT+W, `web-apps toggle`, which opens a new web app
  itself so it opens once, not once per monitor), `WindowSwitcher` and
  `WorkspaceOverview`.
- `CapsuleFeature.qml`: a panel that, on a monitor whose bar is a capsule,
  opens inside the capsule as a bar popup instead of full-screen, decided each
  time it opens: `WallpaperSelector`, `ApplicationLauncher`,
  `ClipboardSelector`, `UnifiedSearch`, `QuickSearch`, `ThemeSelector` and
  `PowerMenu`. Each shares one body between its full-screen panel and its popup
  (`components/panels/*Body.qml`).
- `MonitorChange.qml`: not a `Feature`, it follows `services/MonitorSetups.qml`:
  the *Keep* / *Revert* card on every screen that still works, which takes `Enter`
  and `Esc`, and each monitor's number for *Identify*.
- `MonitorToast.qml`: not a `Feature` either: on the focused monitor, the toast for
  an unknown combination, with the quick switch's choices and *Arrange…*, and any
  failure with the monitors. Each goes by itself after 20 seconds, saving nothing.
- `Bar.qml`: a bar on every monitor, and which popup is open
  (`OpenPopup.js`, tested). Its settings button opens the settings panel on
  that bar: inside its capsule, as the `settings` popup, or centered on any
  other bar style (`Settings.qml`, `SettingsPlace.js`, tested), and a bar element opens its popup (`barElementOpening` tells
  first); one that opens none closes the open popup. Other modules open and close popups through its `openPopup`,
  `bars()`, `focusedMonitor()` and `closePopup()`. Its `capsule toggle`
  IPC call (SUPER+I) expands the focused monitor's capsule, or collapses it
  again; on a normal bar it does nothing (`CapsuleRouting.toggledBar`, tested).
  A capsule hides while its monitor's focused workspace has a real fullscreen
  window, not a maximized one; `bars()` lists that as `capsuleHidden`
  (`CapsuleRouting.hidden`, tested), and SUPER+I does nothing on it.
  `bars()` also lists whether a profile shows new notifications in the
  capsule (`capsuleNotifications`); a capsule that can't show them any more
  hands them back through `capsuleNotificationsReleased`.
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
- `AppMenu.qml`: the app menu popover (SUPER+A, `app-menu` IPC), and what
  every app menu shares, handed as one object through the bar to its bar
  element and Popup: the bridge to apps' own menus (`bridge`) and
  `openPanel(name)` (names in `AppMenuModel.panels`), which closes the app
  menu and opens the Desktop menu's panel in its place.
- `Notifications.qml`: the notification server, toasts and sound, and the
  `notifications` IPC call (SUPER+N, the control center's collapsed
  shortcut). With notifications in the capsule on, a new notification shows
  inside the focused monitor's capsule instead of as a toast
  (`CapsuleRouting.notificationTarget`, which also decides with Do Not
  Disturb and after a reload, tested; the queue with its "+N" is
  `CapsuleNotificationQueue.js`, tested); those the capsule hands back, when
  a popup opens inside it or it hides for fullscreen, show as toasts. Both
  use one card (`NewNotificationCard.qml`, tested): actions, inline reply, and a
  critical one stays until dismissed.
- `BarProfiles.qml`: the default bar profile for new monitors and the
  `bar-profiles` IPC calls.
- `KeepAwake.qml`: the `keep-awake` IPC call the keybind runs, which toggles
  keep-awake and shows the OSD.
- `Osd.qml`: the `osd` IPC calls (the volume and brightness keys), Caps Lock
  and Bluetooth connection watching (`services/BluetoothConnections.js`,
  tested), and where each change event shows: on the focused monitor only, in
  its capsule if it has one and it isn't hidden for fullscreen, else in the OSD
  on that monitor (`CapsuleRouting.changeTarget`, tested).
- `PowerWatch.qml`: watches UPower's display device and shows the power
  change events through `Osd.qml`: "Charging · 64%" and "On battery · 64%"
  on plugging the charger in or out, and "Battery low · 15%" once on reaching
  15% while discharging, re-armed like the low-battery notification. Nothing
  shows without a battery or for the first reading at startup
  (`services/PowerChange.js`, tested).
- `Lock.qml` (the one lock screen and the `lock` IPC call) and
  `LowBattery.qml` (the low-battery notification, which stays alongside the
  "Battery low" change event).
- `FailedReload.qml`: the failed reload notice. When a live reload fails the
  shell still running the previous config raises a critical notification
  with the first error line; the next successful reload withdraws it. The
  notice's id survives the reload as a persistent property; what it shows and
  withdraws is `FailedReload.js` (tested).

These files import Quickshell, so they can't be loaded under the tests; what
they decide that is more than wiring lives in plain JS.
