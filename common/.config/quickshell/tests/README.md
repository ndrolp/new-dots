# Tests

Tests for the pure JS models behind the settings: bar profiles
(`config/BarProfileModel.js`), desktop widgets (`config/DesktopWidgetsModel.js`)
and schema migrations (`config/SchemaMigrations.js`). They also cover the
popups: where a popup opens (`components/panels/PopupPlacement.js`), the
outline of an attached popup (`PopupOutline.js`), the surface every popup
draws on (`PopupSurface.qml`), the shared popup parts (`PopupTitle`,
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
(`ConfigPanel.qml`) and the settings panel sections built from them, the Bluetooth device list and turning Bluetooth
on (`BluetoothDevices.js`, `BluetoothPower.js`), how an audio output is named
(`AudioOutputs.js`), how the volume is shown as text
(`components/VolumeText.js`), what the popups and bar elements show for the
media position, audio outputs, Wi-Fi, the battery and the network
(`components/StatusText.js`) and what the audio bar element shows and how
wide it is (`components/bar/AudioLevel.qml`), how the Cava bar element
reads cava and tries it again when it fails (`services/CavaOutput.js`) and
what it draws (`components/bar/CavaBars.qml`), how long animations take
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
(`components/panels/ColorschemePreview.js`).
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

`startup.sh` checks that `start.sh` creates the machine-local colorscheme links
(`colorschemes/active` and `shown`) before Quickshell starts, through the
colorscheme changer's harness, so no live session is touched:

```sh
common/.config/quickshell/tests/startup.sh
```
