# Tests

Tests for the pure JS models behind the settings: bar profiles, with a name
to ask a profile for each bar style (`config/BarProfileModel.js`), desktop widgets (`config/DesktopWidgetsModel.js`)
and schema migrations (`config/SchemaMigrations.js`), among them the one that
turns the two bar style switches into one bar style and keeps each saved
profile's look (`tst_barStyleMigration.qml`), and the one that turns a capsule
profile's list of shown bar elements into collapsed places
(`tst_barProfileModel.qml`), and the one that splits the pomodoro out of the
clock, right after it, in its group and on or off as the clock was, and the
one that places it live right in a capsule, after the recording indicator,
and the one that puts the privacy indicator right after the recording
indicator, in its group and on or off as it is, live right between it and
the pomodoro, neither added twice to a profile that already lists it
(`tst_barElements.qml`), and the one that drops the unread workspace padding
from every saved profile (`tst_densityPresets.qml`). That a migration writes
both files ending in a newline, as the adapters do, and that the tracked
`config/appearance.json` and `monitors.json` are committed already migrated,
so the shell's first run leaves the checkout clean, is in
`tst_schemaMigrationFiles.qml`. They also cover where
the bar sits on its screen: the edges its window is anchored to, the space it
reserves (on a capsule, with the live elements it shows collapsed), where the margin goes and where its content sits, against its edge
however tall a capsule's window grows, for every bar style on each Bar position
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
bar, and that on a capsule a popup is inside it, centred on it right past its
row with no room round it (`components/panels/PopupPlacement.js`), the outline of an attached popup
on each of them (`PopupOutline.js`), the surface every popup draws on, how
it reveals away from the bar, that inside a capsule it draws only its
contents, and that it ignores input while closing (`PopupSurface.qml`; `PopupFrame.qml` itself is a Quickshell window and isn't
tested here), that a popup's reveal waits for its freshly mapped window's
first frames (`PopupWarmUp.qml`), what a popup's focus grab holds
(`PopupGrab.js`), which bar elements close the open popup when pressed
(`BarPopupCloser.qml`), and that the settings button's press leaves the settings panel inside
a capsule to its own click (`OpenPopup.pressedWithoutPopup`), the shared popup parts (`PopupTitle`,
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
`SettingsSwitchRow`, `SettingsChoice`, `SettingsGrid`…: a long label wraps instead of
eliding, and a grid too narrow for two cells side by side is one column; `SettingsCard`:
the hairline-bordered card, half transparent, one step lighter than the panel and without hover,
that holds a headed group), the one
hover they share (`SettingsHoverFill`: a faint fill that stands out from the card they sit on, a pointing hand, an accent border on bordered
controls, a growing slider thumb, a brighter switch, instant under reduce
motion), its frame
(`ConfigPanel.qml`: the colorscheme's surface at 85% opacity as its fill, each section's title and description from its entry in
the sections list, the header's title, search and Done at the panel's
margins, the selected sidebar section's fill, accent bar and accent text, its
view (section, search text, scroll position) that another panel picks up,
every section's content in cards 12px apart, its text inside their padding,
and Escape closing it like Done, on the panel and while typing in its search
field),
its search landing on a setting (`tst_settingsSearch.qml`, `SettingsSearch.js`:
a setting's label lists it in the sidebar under its section, only when the
edited profile's bar style shows it; choosing it, or Enter on the first
match, opens its section, scrolls it into view and flashes it with the accent;
section-only matches still list just the section; a Wallpapers setting of
another view (Schedule) switches the section to that view first; and the
sections list's index of setting labels matches what each section shows on
every bar style, every section included: those that need Quickshell through
the parts they are built from, `DesktopWidgetsMonitorSettings.qml`,
`SessionActions.qml` and each view of `WallpaperSettingsBody.qml`)
and the settings panel sections built from them, among
them the four Bar positions and the zone names of a side bar, which keep their
saved keys, the bar style as one choice of every style the profile model lists, and the Bar section as one scroll of cards in order (Profile, Style, Bar, Groups, Elements, and Capsule only for a capsule), each with only the settings the bar uses on the edited profile's bar style, shown or hidden as soon as the style changes and a card with none of them hidden whole (`tst_barSettingStyles.qml` covers which settings each bar style shows, `BarProfileModel.barSettingShown`), no workspace bar padding (nothing on the bar reads it), Edge margin (stored under `transparentBarTopMargin`) keeping its stored value, and searching its card names landing on it (`BarSettings.qml`, `BarSizeStyleSettings.qml`, `BarElementsSettings.qml`, `ConfigPanel.qml`), the Bluetooth device list and turning Bluetooth
on (`BluetoothDevices.js`, `BluetoothPower.js`), how an audio output is named
(`AudioOutputs.js`), how the volume is shown as text
(`components/VolumeText.js`), what the popups and bar elements show for the
media position, audio outputs, Wi-Fi, the battery and the network
and how a value stands on a side bar (`components/StatusText.js`) and what the audio bar element shows and how
wide it is (`components/bar/AudioLevel.qml`), how scrolling turns into
steps, at most one per wheel notch or touchpad gesture, its momentum and a
touchpad with no scroll phases included (`components/WheelSteps.js`,
`WheelStepHandler.qml` feeds it), and that a step over the media bar element skips its player to the next or
previous track where it can (`MediaCard.skipTrack`), how the Cava bar element
reads cava and tries it again when it fails (`services/CavaOutput.js`) and
what it draws, from the bottom or from the side, and the track progress painted on its bars (`components/bar/CavaBars.qml`), what the Cava desktop widget shows of the player: the media info, the progress line and when they show (`components/widgets/CavaMedia.js`, `CavaMediaInfo.qml`), how a docked bar zone hangs
from the screen edge the bar sits on and keeps its sides on the screen's edge
straight, on each Bar position (`PopupOutline.js`), and how it is
drawn, grows for an attached popup, keeps up with one that resizes and meets
its joins on every Bar position
(`components/bar/DockedSurface.qml`,
`DockedZones.js`), which bar elements a collapsed capsule shows in its one
row (the ones its profile chose, in the profile's order, else Arch, the clock
and the control center; the choice is kept with the profile by
`BarProfileModel.js` and offered, on a capsule profile, for the elements the
profile shows but the workspaces and the live ones by
`BarElementsSettings.qml`, and a saved choice of those is ignored), which ones it shows expanded
(all but the workspaces and the live ones, with their groups), which are its
live elements and on which side of the workspace pills (media left, shown
collapsed only while a track plays and expanded while any player exists, the
recording indicator, the privacy indicator (shown only while an app uses the
microphone or a camera) then the pomodoro right, the pomodoro shown collapsed
only while started, paused included, keep-awake hidden unless chosen, then
shown collapsed only while on), never in its row, at 80% of the profile's sizes
and out of any group, whose rest keeps one background
(`components/bar/CapsuleElements.js` for the row, `LiveElements.js` for the
live elements, `BarElementItems.js`), that only the
pointer over the capsule itself counts as hovering it, where the capsule sits
around that row and its pill row, where the pills and the live elements go in
that row, centred and closing up when one isn't shown, and that only the
capsule takes clicks in its bar window (`CapsulePlacement.js`), that the
at-rest row, for profiles mixing shown, live (left and right) and hidden
elements like the island one, shows its elements evenly apart, centred on the
capsule and on its pill row with equal padding at both ends, the square
network, Bluetooth and tray elements padded like the others unless they draw
their own pill (`tst_capsuleRestingRow.qml`, `BarElementItems.elementLength`), that any one cause holds it expanded and that
SUPER+I acts only on the focused monitor's capsule (`CapsuleRouting.js`),
that hovering it expands it only after a moment and collapses it a while after
the pointer leaves (`CapsuleHover.qml`), that SUPER+I holds it expanded until
pressed again or until the pointer leaves it (`CapsuleToggle.qml`), that a
change (volume, brightness, Caps Lock, audio output, bar profile,
keep-awake, Do Not Disturb, a Bluetooth connection or power) goes to the focused
monitor's capsule instead of the OSD, nowhere
while a popup is inside it, and otherwise to the OSD on the focused monitor's
screen, also while its capsule is hidden because its focused workspace has a
real fullscreen window, which only a capsule does and SUPER+I then leaves
alone (`CapsuleRouting.js`; whether a workspace has one, not just a maximized
window, is `WorkspaceState.hasFullscreen`), and that the capsule then shows that change
and no bar element (`CapsuleElements.js`), for about 1.5 s from the latest one (`CapsuleChange.qml`),
what each change shows in the OSD (`components/panels/OsdChange.js`), and
in the capsule (`OsdChange.capsuleLook`, `levelIcon`): volume and brightness
as a wide fill bar with a glyph that follows the level (muted, the
struck-through speaker and an empty grey bar) and bounces on each change but
not under reduce motion, battery and Bluetooth as a glance card with one line
and a small ring of the battery level, the device's own for Bluetooth when it
reports one (`CapsuleChangeView.qml`, `tst_capsuleChangeView.qml`), which Bluetooth devices connected or
disconnected since the last read, none of those connected at start
(`services/BluetoothConnections.js`), which power change event a battery
reading makes: plugging in, unplugging, and "Battery low" once at 15% while
discharging, re-armed like the notification, none at startup or without a
battery (`services/PowerChange.js`, `tst_powerChange.qml`), in the same tone colours and with the
same level bar and percent, under the bar in the OSD and beside it in the
capsule (`OsdChange.toneColor`, `ChangeLevel.qml`), that Do Not Disturb
shows each time it is turned on or off but not as the shell starts
(`components/panels/DoNotDisturbWatch.qml`), that with notifications in the
capsule on (a profile setting, off in new and migrated profiles, offered in the
settings panel only for a capsule: `tst_capsuleNotifications.qml`,
`BarSettings.qml`) a new notification goes to the focused monitor's
capsule and is a toast with the setting off, a popup or panel inside, the
capsule hidden for fullscreen or no capsule, and nowhere new with Do Not
Disturb or after a reload, which also keep it quiet
(`CapsuleRouting.notificationTarget`, `holdsNotifications`, `announced`, all
on one `capsuleAvailable` that SUPER+I and a change share),
that the newest shows with the others waiting as "+N", the next showing as
one ends and all handed back oldest first as toasts
(`CapsuleNotificationQueue.js`), and the card a new notification shows as,
toast or in the capsule: its timeout, a critical one staying, its actions,
inline reply and "+N" (`components/panels/NewNotificationCard.qml`,
`NotificationCard.newNotificationTimeout`), how it is
drawn with its fill and bar border, that it springs to a new size (growing
overshoots slightly and settles, shrinking doesn't bounce), its corners morph
on the same spring and reduce motion moves it at once (`CapsuleSurface.qml`),
which spring a size change takes and how its contents look a given time into a
crossfade (`CapsuleMotion.js`, `tst_capsuleMotion.qml`), that its contents
crossfade between views by key, the old one fading and shrinking away before
the new one shows and fades and grows in (`CapsuleContentTransition.qml`),
which view its row shows (`CapsuleRouting.rowView`), that a popup inside it
crossfades its contents on the capsule's timings (`PopupSurface.qml`), that its corners come down round a
popup inside (`CapsulePlacement.withPopup`), that it reaches past its row for its
workspace pills, and where they sit inside it, under the row of a top
capsule and above the row of a bottom one, centred on it, how it grows round a popup
inside it (`CapsulePlacement.js`), that its window grows at once for a popup inside and
never shrinks back (`CapsuleWindowHold.qml`), that the
pills are small and unlabelled, one per workspace in order, highlight the
active one as it changes, switch workspace on a click and go to the next or
previous one on a scroll, as the bar's workspaces element does, stopping at
either end (`CapsuleWorkspaceRow.qml`, `Workspaces.qml`), that a mouse wheel
steps once per notch and a touchpad gesture at most once
(`components/WheelSteps.js`; `WheelStepHandler.qml` feeds it), and that a capsule sits only at the top or
bottom, where zones, bar elements, group backgrounds and popup
triggers sit along either axis of the bar, to the pixel the anchors they
replaced put them at (`components/bar/BarLayout.js`; `BarContent.qml` itself
needs Quickshell's services and isn't tested here), how workspaces, icon
and value elements size and stack upright on a side bar and stay as they were
on a top one (`BarLayout.size`, `Workspaces.qml`, `ArchButton.qml`,
`KeepAwakeElement.qml`, `ElementText.qml`, `IconValue.qml`, `AudioLevel.qml`,
`SystemMonitor.qml`, `RecordingContent.qml`; `BarElementItems.qml` and `Clock.qml`
need Quickshell's services, so their parts are covered through those), that what
runs along the bar animates and what runs across it doesn't, on every Bar position
(`AlongBarBehavior.qml`), that a bar element that can be live sits at its place,
as large as its item, and fades out as a live element, keeping its room beside
the pills until its fade-out ends, at once with reduce motion
(`LiveCapableItem.qml`), what the workspace overview lists: every monitor's
workspaces in physical order, each one once, how they fit up to 21 with no
scrolling, what each key does, during a drag too, how the keyboard walks them,
the number a new one takes, skipping numbers another monitor has or the rules
bind to it, and where a window sits in its miniature at any monitor scale or
rotation (`components/panels/WorkspaceOverview.js`; `WorkspaceOverview.qml`,
`WorkspaceMiniature.qml` and `MiniatureWindow.qml` need Quickshell and aren't
tested here), which windows a miniature shows and what focusing, moving a window
and creating a workspace dispatch, where a scroll over a monitor's workspaces
goes and the switch one step makes, shared by the bar's workspaces element
and the capsule's pills (`services/WorkspaceState.js`;
`WorkspaceService.qml` needs Quickshell and isn't tested here), a monitor's
heading and when its + shows (`components/panels/WorkspaceMonitorHeader.qml`),
what dropping a window on the new workspace slot and clicking it do
(`components/panels/NewWorkspaceSlot.qml`, `WorkspaceDropSurface.qml`), when a window's thumbnail lies over its
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
with and without reduce motion, the capsule's springs and contents timings
among them (`config/Motion.js`), night light's
temperature bounds, the saved temperature, how hyprsunset is run and when
night light turns on and off (`services/NightLightState.js`), when the lock screen
locks, checks a password and unlocks (`components/lock/LockState.js`) and what it
shows on each monitor (`components/lock/LockScreenBody.qml`), what a unified
search query asks for: its query mode, whether it is maths for the
calculator and how qalc is run and answers
(`components/panels/SearchQuery.js`), which emoji the emoji picker finds
(`components/panels/EmojiSearch.js`), and how the keybind cheatsheet groups
and filters `hyprctl binds -j` (`components/panels/KeybindCheatsheet.js`),
the printers the Printers panel lists, read from `lpstat` output, with their
state, network or USB and the default, their print jobs read from `ipptool`,
and the `lpadmin`, `cancel` and `lp` commands that change them
(`services/Printers.js`), what its rows say of a printer, a print job and a
connection (`components/panels/PrinterLabels.js`), that a polled list is
only replaced when it changes (`services/Assign.js`), and its *Printers*
heading: the empty list, each printer's row and opening one for its print
jobs, *Set default*, *Test page* and *Remove*
(`components/panels/PrintersSection.qml`), the discovered printers read from
`avahi-browse -rpk` (escapes, TXT records, one printer seen several ways,
this computer's own printers and the ones already added left out), the
printer name and `lpadmin` command an *Add* runs and why one failed
(`services/PrinterDiscovery.js`), and the *Discovered printers* heading:
*Add*, adding, a failed add and a printer that can't print driverless
offering *Print settings*, and why none can be found
(`components/panels/DiscoveredPrintersSection.qml`), the scanners it lists
from `scanimage -f` output (webcams left out, network or USB), the colour
modes a scanner offers from `scanimage -A` and the nearest one to a
remembered mode, how a scan is named, run and reports progress, its outcome
or its error, the *Show in folder* URI, and the scan settings kept in
`appearance.json` (`services/Scanners.js`; `scan.sh`, below, runs the scan
wrapper; `ScannersSection.qml` and `ScanView.qml` have no tests yet,
`DeviceRow.qml` is tested through the sections, and `PrintersPanel.qml`,
`FocusedMonitorPanel.qml` and the services' `.qml` files need Quickshell
and aren't tested here),
the Android devices panel's rules: `adb devices -l` and `adb mdns services`
read into one row per Android device with its state, known devices merged
in and remembered (not before a Wi-Fi connection's serial is known), the
address Connect tries, what `adb connect` answered in its several
wordings, each row action's label and service method, and the Android
device's Wi-Fi address from its default route
(`services/AndroidDevices.js`, against output captured from a Pixel 10a),
pairing: the QR code's payload, the pairing services, what `adb pair`
answered and what is said when a paired Android device didn't connect
(`services/AndroidPairing.js`), its device list with each row's state and
actions (`components/panels/AndroidDevicesSection.qml`) and its *Pair new
device* section: the QR code, the pairing code fields filled from mDNS
(`components/panels/AndroidPairingSection.qml`; `AndroidDevicesPanel.qml`
and the services' `.qml` files need Quickshell and aren't tested here;
`android-pairing.sh`, below, runs `services/AndroidPairing.qml`),
which apps the privacy indicator sees using the microphone or a camera in
the PipeWire graph, not counting cava, level meters, the shell itself, a
filter's own capture or a screen share, the icons it shows and what its
popup lists under each device kind (`components/bar/PrivacyIndicator.js`,
`components/panels/PrivacyPopupBody.qml`; `services/DeviceCaptures.qml`
needs Quickshell and isn't tested here),
what the keep-awake bar element shows, with a countdown's time left only as a
capsule's live element, and its popup's switch, duration choice
and time left (`components/bar/KeepAwakeElement.qml`,
`components/panels/KeepAwakePopupBody.qml`), keep-awake's duration and
countdown: starting, restarting, running out and turning off by hand, the
coarse time left a live element shows, and
what the keybind's OSD says (`services/KeepAwakeState.js`),
the failed reload notice: what a failed live reload shows (critical, the first
error line, as text), a repeat failure replacing it and the next successful
reload withdrawing it (`modules/FailedReload.js`; `FailedReload.qml` needs
Quickshell and isn't tested here),
the wallpapers of a folder as the wallpaper popup, the selector and the
Wallpapers section list them: each row and thumbnail is the file it was
listed from, never the folder plus its name, so a folder switched while the
first is still being listed never gives a thumbnail a file that isn't there
(`config/WallpaperFiles.qml`, `WallpaperThumbnail.qml`; `tst_wallpaperFiles.qml`,
and `tst_wallpaperSettings.qml` for the section's tiles),
which popup is open across the bars and which bar IPC opens one on
(`modules/OpenPopup.js`), where the settings panel opens: inside the capsule of the bar it is
asked from, or of the focused monitor's for IPC and other panels, centered on any other bar and
while that capsule is hidden for a fullscreen window, which of those closes it, and
that it follows a live bar style change on its bar, moving between the two and staying open
(`modules/SettingsPlace.js`; the popup inside, `SettingsPopup.qml`, is a Quickshell window and isn't
tested here), one part of the shell opening another in its
place unless its plugin is off (`modules/SwitchTo.js`), which bar element a popup opens under
and that the pomodoro shows only while one is started
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
Monitor setups are covered too: where monitors snap, edge to edge with no gaps
(`services/MonitorArrangement.js`), resolution, refresh and scale choices
(`services/MonitorModes.js`), what a setup holds, how it changes, values an
imported setup leaves that aren't numbers, and the saved file, including one that
couldn't be loaded (`services/MonitorEntries.js`), the *Keep* / *Revert* countdown,
what a change needs, what follows each answer from Hyprland and Hyprland going
back by itself (`services/MonitorChange.js`), and the Displays section and its
card with its keys
(`components/panels/MonitorArrangeSettings.qml`, `MonitorArrangeCanvas.qml`,
`MonitorControls.qml`, `MonitorSavedSetups.qml`, `MonitorChangeCard.qml`; `services/MonitorSetups.qml`,
its 5-second limit on `hyprctl`, and
`modules/MonitorChange.qml` need Quickshell and aren't tested here), and the quick
switch: its choices and the setup each builds, what *Extend* brings back and how a
kept choice is saved (`services/QuickSwitch.js`), and its keys
(`components/panels/QuickSwitchList.qml`; `QuickSwitch.qml` and
`modules/QuickSwitch.qml` need Quickshell and aren't tested here), and the
toasts about monitors: when an unknown combination is offered, waiting for
unlock, and telling a fallback or an unreadable file once
(`services/MonitorToast.js`), and the cards
(`components/panels/MonitorToastCard.qml`, `MonitorNoticeCard.qml`;
`modules/MonitorToast.qml` needs Quickshell and isn't tested here).
`monitor-notices.sh` runs `services/monitor-notices.sh` on a scratch folder, to
show that a backup is told once and never replaces another.
They run with QtTest outside of `qs`, also from `scripts/test-all`:

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
  model returns (`withChanges`, `edited`). `fixtures/wallpapers/` holds a
  horizontal and a vertical wallpaper folder for `tst_wallpaperFiles.qml`: a
  folder switched while the first is still being listed never gives a
  thumbnail a file that isn't there.
- The script uses the Qt 6 `qmltestrunner` (`/usr/lib/qt6/bin/qmltestrunner`;
  override with `QMLTESTRUNNER`). Extra arguments go to `qmltestrunner`, e.g.
  `run.sh test_savingUnderANewNameAddsAProfile`.

`state-files.sh` checks that Quickshell's runtime state (`services/launcher.json`,
`config/wallpapers.json`, `config/android-devices.json`) is untracked and gitignored while `appearance.json`
stays tracked, and starts a headless `qs` on a scratch config to check that
the launcher history, wallpaper and Android devices services create those files when missing:

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

`webapps.sh` runs `services/webapps.py` on a scratch `XDG_DATA_HOME`, offline:
creating a web app's entry and icon, listing only web apps, refusing the same
URL twice, keeping `%` and quotes in the `Exec` key, and deleting only web
apps. The rules in `services/WebApps.js` are in `tst_webApps.qml`:

```sh
common/.config/quickshell/tests/webapps.sh
```

`scan.sh` runs `services/scan.sh`, the Printers panel's scan wrapper, with a
fake scanimage that writes `<file>.part` the way scanimage 1.4 does: a saved
scan, a failed one whose `.part` is removed, a scan saved before scanimage
failed (kept, exit 100), and a file already there left alone. It is in
`scripts/test-all`:

```sh
common/.config/quickshell/tests/scan.sh
```

`android-pairing.sh` runs `services/AndroidPairing.qml` in a headless `qs`
with a fake adb and a stand-in Android devices service, touching no
Android device: a QR code scanned while adb is busy is paired once it is
free, and a paired Android device that connects is named while one that
doesn't says why. It is in `scripts/test-all`:

```sh
common/.config/quickshell/tests/android-pairing.sh
```

`startup.sh` checks that `start.sh` creates the machine-local colorscheme links
(`colorschemes/active` and `shown`) before Quickshell starts, and starts it
with Quickshell's own reload popup off (`QS_NO_RELOAD_POPUP=1`; the failed
reload notice says it instead), through the
colorscheme changer's harness, so no live session is touched:

```sh
common/.config/quickshell/tests/startup.sh
```
