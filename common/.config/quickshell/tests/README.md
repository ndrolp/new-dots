# Tests

Tests for the pure JS models behind the settings: bar profiles
(`config/BarProfileModel.js`), desktop widgets (`config/DesktopWidgetsModel.js`)
and schema migrations (`config/SchemaMigrations.js`). They also cover where
the bar sits on its screen: the edges its window is anchored to, the space it
reserves and where the margin goes, for every bar style on each Bar position
(`components/bar/BarPlacement.js`; `Bar.qml` itself is a Quickshell window and
isn't tested here), and where the toasts and desktop widgets sit in the area
the bar leaves free: their anchors and plain gaps from that area
(`components/panels/NotificationPlacement.js`, `config/DesktopWidgetsModel.js`;
that the compositor keeps their windows and the OSD inside it depends on
`ExclusionMode.Normal` on those windows and isn't tested here). They also cover
the popups: what a Bar position means for what is laid out from the bar
(`components/BarPosition.js`), where a popup opens on each Bar position, the
stretch of the bar that opens it, how wide its contents are, and that a popup
held through a control center stage change stays steady and on screen on a side
bar (`components/panels/PopupPlacement.js`), the outline of an attached popup
on each of them (`PopupOutline.js`), the surface every popup draws on, how
it reveals away from the bar and that it ignores input while closing
(`PopupSurface.qml`; `PopupFrame.qml` itself is a Quickshell window and isn't
tested here), what a popup's focus grab holds
(`PopupGrab.js`), which bar elements close the open popup when pressed
(`BarPopupCloser.qml`), the shared popup parts (`PopupTitle`,
`PopupHeader`, `PopupRow`…), the control center's tiles and sliders,
active, muted, disabled and icon-only (`ControlTile.qml`, `ControlSlider.qml`;
`ControlCenterBody.qml` itself needs Quickshell's services and isn't tested
here), the control center's collapsed and expanded stages: the stage each
way of opening it asks for, the chevron and the drag on its handle, and
notifications only with its plugin off, and the ongoing notifications on
top in both stages (`ControlCenterLayout.qml`): the media card above the
`resident` notifications, their highlighting and dismissing one
(`ControlCenterOngoing.qml`), the media card itself: which
player it follows, the track and its playback controls
(`ControlCenterMediaCard.qml`, `MediaCard.js`), its
audio output subpage: opening it in place of the controls, the back arrow,
the outputs it lists and choosing one (`ControlCenterLayout.qml`,
`ControlCenterAudioOutputs.qml`), the control center's tile list: its order,
hidden tiles, the collapsed row of the first 6 visible tiles and the
migration that seeds it (`config/ControlCenterTiles.js`), and the settings
panel's Control center section that edits it (`ControlCenterSettings.qml`),
the settings panel's own parts (`SettingsNumber`,
`SettingsSwitchRow`, `SettingsChoice`, `SettingsGrid`…), its frame
(`ConfigPanel.qml`) and the settings panel sections built from them, among
them the four Bar positions and the zone names of a side bar, which keep their
saved keys (`BarSizeStyleSettings.qml`, `BarElementsSettings.qml`), the Bluetooth device list and turning Bluetooth
on (`BluetoothDevices.js`, `BluetoothPower.js`), how an audio output is named
(`AudioOutputs.js`), how the volume is shown as text
(`components/VolumeText.js`), what the popups and bar elements show for the
media position, audio outputs, Wi-Fi, the battery and the network
and how a value stands on a side bar (`components/StatusText.js`) and what the audio bar element shows and how
wide it is (`components/bar/AudioLevel.qml`), how the Cava bar element
reads cava and tries it again when it fails (`services/CavaOutput.js`) and
what it draws, from the bottom or from the side (`components/bar/CavaBars.qml`), how a docked bar zone hangs
from the screen edge the bar sits on and keeps its sides on the screen's edge
straight, on each Bar position (`PopupOutline.js`), and how it is
drawn, grows for an attached popup, keeps up with one that resizes and meets
its joins on every Bar position
(`components/bar/DockedSurface.qml`,
`DockedZones.js`), where zones, bar elements, group backgrounds and popup
triggers sit along either axis of the bar, to the pixel the anchors they
replaced put them at (`components/bar/BarLayout.js`; `BarContent.qml` itself
needs Quickshell's services and isn't tested here), how workspaces, icon
and value elements size and stack upright on a side bar and stay as they were
on a top one (`BarLayout.size`, `Workspaces.qml`, `ArchButton.qml`,
`KeepAwakeElement.qml`, `ElementText.qml`, `IconValue.qml`, `AudioLevel.qml`,
`SystemMonitor.qml`, `RecordingContent.qml`; `BarElementItems.qml` and `Clock.qml`
need Quickshell's services, so their parts are covered through those), that what
runs along the bar animates and what runs across it doesn't, on every Bar position
(`AlongBarBehavior.qml`), what the workspace overview lists: every monitor's
workspaces in physical order, each one once, how they fit up to 21 with no
scrolling, how the keyboard walks them, the number a new one takes, where a
window sits in its miniature at any monitor scale or rotation and which windows
a miniature shows (`components/panels/WorkspaceOverview.js`; `WorkspaceOverview.qml` itself is a
Quickshell window and isn't tested here), when a window's thumbnail lies over its
icon and title (`components/panels/WindowThumbnail.qml`; `WindowFrames.qml`, which
captures the frames, needs Quickshell and isn't tested here), what a press on a
window ends as and what ends a drag early (`components/panels/WindowDrag.qml` and
`WindowDropTarget.qml`; `WindowDragGhost.qml` needs Quickshell and isn't tested
here), how the long text of the app
menu, the current app and the media element turns on a side bar: how far, what
its length is capped against and where an app menu title ends up for its popup,
checked against a really rotated item (`BarLayout.turn`, `BarLayout.screenLength`,
`BarLayout.turnedArea`; `AppMenu.qml` and `CurrentApp.qml` need Quickshell's
Hyprland, so the elements themselves aren't tested here), how long animations take
with and without reduce motion (`config/Motion.js`), night light's
temperature bounds, the saved temperature, how hyprsunset is run and when
night light turns on and off (`services/NightLightState.js`), when the lock screen
locks, checks a password and unlocks (`components/lock/LockState.js`) and what it
shows on each monitor (`components/lock/LockScreenBody.qml`), what a unified
search query asks for: its query mode, whether it is maths for the
calculator and how qalc is run and answers
(`components/panels/SearchQuery.js`), which emoji the emoji picker finds
(`components/panels/EmojiSearch.js`), and how the keybind cheatsheet groups
and filters `hyprctl binds -j` (`components/panels/KeybindCheatsheet.js`),
what the keep-awake bar element shows and its popup's switch, duration choice
and time left (`components/bar/KeepAwakeElement.qml`,
`components/panels/KeepAwakePopupBody.qml`), keep-awake's duration and
countdown: starting, restarting, running out and turning off by hand, and
what the keybind's OSD says (`services/KeepAwakeState.js`),
which popup is open across the bars and which bar IPC opens one on
(`modules/OpenPopup.js`), one part of the shell opening another in its
place unless its plugin is off (`modules/SwitchTo.js`), which bar element a popup opens under
(`components/bar/BarElementItems.js`), the notifications in the control
center: marking them read on open, highlighting the ones that arrived since
you last looked, Clear all, that ongoing notifications stay out of
the list, and app stacks: an app's notifications
stacked under the newest card with "+N more", expanding and collapsing, and
swiping a stack away (`components/panels/ControlCenterNotifications.qml`,
`NotificationStack.qml`), the notification
card: the image or app icon it shows, the chevron, tapping it (default
action or expand), its action buttons, the × and how far a swipe has to go
to dismiss it, and an ongoing card staying after its actions run
(`components/panels/NotificationCard.qml`,
`NotificationCard.js`), what the notification history keeps of a
notification, how it groups them by app and dismisses a whole group,
dismissing a notification whenever its card leaves the history (a card,
a stack or Clear all removed, a repeat, the 50-card cap, which never
drops an ongoing one), a card following a notification the app replaces
in place, and rebuilding
the history from the notifications kept over a reload, and the ongoing
notifications (`resident`) that Clear all and a stack swipe keep and that
leave when their app closes them
(`services/NotificationHistory.qml`),
the active colorscheme's colours read from its colours file,
falling back to everforestdark's (`config/ColorschemeColors.js`), and which
colorscheme preview the colorscheme selector runs, one at a time
(`components/panels/ColorschemePreview.js`), and the app menu: the menus
its model builds for the focused window, the app-name menu and how Quit
closes every window of the app, the app's own menus made from what it
exports over DBusMenu or GTK's org.gtk.Menus, the "»" menu for the titles
that don't fit and the shell's Window menu renamed Hyprland
(`components/AppMenuModel.js`), how a
menu is drawn, with submenus opening in place
(`components/panels/AppMenuList.qml`), what the app menu popover lists and
where it opens at the cursor (`components/panels/AppMenuPopover.js`), and
which window the bar elements that follow the focused window see and on
which monitor's bar they show (`components/FocusedWindow.js`).
They run with QtTest outside of `qs`:

```sh
common/.config/quickshell/tests/run.sh
```

- Test files are `tst_*.qml` (QtTest `TestCase`) and import the models they
  test, e.g. `import "../config/BarProfileModel.js" as BarProfileModel`, or
  the panels, `import "../components/panels" as Panels`. Quickshell's own
  modules (`Quickshell.Io`, `Quickshell.Bluetooth`…) don't load under
  `qmltestrunner`, so only files that don't import them can be tested here.
  A section that needs one keeps it in a thin wrapper and is tested through
  what the wrapper hands it, e.g. `WallpaperSettings.qml` passes Hyprland's
  monitors to `WallpaperSettingsBody.qml` as plain displays.
- `fixtures/` holds copies of the real `appearance.json` and `monitors.json`
  (schema version 0, from before bar profiles were reworked), and a slice of
  real `hyprctl binds -j` output (`hyprctl-binds.json`). Read them with
  the shared `Fixtures` helper (`Fixtures.qml`): declare
  `Fixtures { id: fixtures }` in the test and call
  `fixtures.read("appearance.json")`. It also gives the fixtures migrated to
  the current schema (`migrated()`), the in-memory bar profile state Quickshell
  starts with (`startedBarState()`), and helpers to apply the changes the
  model returns (`withChanges`, `edited`).
- The script uses the Qt 6 `qmltestrunner` (`/usr/lib/qt6/bin/qmltestrunner`;
  override with `QMLTESTRUNNER`). Extra arguments go to `qmltestrunner`, e.g.
  `run.sh test_savingUnderANewNameAddsAProfile`.

`state-files.sh` checks that Quickshell's runtime state (`services/launcher.json`,
`config/wallpapers.json`) is untracked and gitignored while `appearance.json`
stays tracked, and starts a headless `qs` on a scratch config to check that
the launcher history and wallpaper services create those files when missing:

```sh
common/.config/quickshell/tests/state-files.sh
```

`app-menu-bridge.sh` runs the real `services/app-menu-bridge.py` against a fake
app (`fixtures/fake-menu-app.py`) on a private session bus, with no display: it
finds a native Wayland window's menubar, a `GtkApplication`'s and its actions,
runs a chosen item, shows nothing for hidden menubars or several windows, and
isn't held up by a connection that never answers:

```sh
common/.config/quickshell/tests/app-menu-bridge.sh
```

`startup.sh` checks that `start.sh` creates the machine-local colorscheme links
(`colorschemes/active` and `shown`) before Quickshell starts, through the
colorscheme changer's harness, so no live session is touched:

```sh
common/.config/quickshell/tests/startup.sh
```
