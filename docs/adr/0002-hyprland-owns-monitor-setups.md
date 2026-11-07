# Hyprland's Lua config owns monitor setups

Monitor setups need to apply at startup and on hotplug, before the shell has started and after it has crashed. We decided that Hyprland's Lua config matches the connected monitors and applies the setup, reading one saved file. The shell only edits that file and shows the screens around it. This replaces `hyprdynamicmonitors`, whose per-machine templates had to be written by hand and had to match the config format, which is how sodoma and `docked.go.tmpl` ended up writing a format Hyprland no longer read. Having the shell do the matching would have been simpler to build, but nothing would handle a hotplug without it.

## Consequences

- With no saved setup, or a file that can't be read, Hyprland still extends automatically, so a screen always works without the shell.
- `hl.monitor` starts from the existing rule for that monitor, so a setup writes every field. Otherwise a rotation or `disabled` carries over from the previous setup. `icc` is the exception: Hyprland rejects an empty one, so a rule can't clear one from an earlier setup.
- Saved setups are machine-local, like the active colorscheme, so moving a monitor leaves `git status` clean and a fresh install starts with none.
- The shell asks Hyprland to apply the file with `hyprctl eval` on `apply_now`, because Hyprland doesn't watch it and a reload would rebuild the whole config for a change of monitors.
- Hyprland only reads the file, but it leaves side files beside it for the shell: `.bad`, a file it couldn't read, kept under a name of its own, and `.fallback`, the monitors whose saved mode is gone. A change being tried out is in the file too, so the file holds `unkept`, what to go back to. Hyprland honours that without the shell, on load and a few seconds past the countdown, so a trial never counts as saved.
