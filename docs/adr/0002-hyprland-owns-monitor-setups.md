# Hyprland's Lua config owns monitor setups

Monitor setups need to apply at startup and on hotplug, before the shell has started and after it has crashed. We decided that Hyprland's Lua config matches the connected monitors and applies the setup, reading one saved file. The shell only edits that file and shows the screens around it. This replaces `hyprdynamicmonitors`, whose per-machine templates had to be written by hand and had to match the config format, which is how sodoma and `docked.go.tmpl` ended up writing a format Hyprland no longer read. Having the shell do the matching would have been simpler to build, but nothing would handle a hotplug without it.

## Consequences

- With no saved setup, or a file that can't be read, Hyprland still extends automatically, so a screen always works without the shell.
- `hl.monitor` starts from the existing rule for that monitor, so a setup writes every field. Otherwise a rotation or `disabled` carries over from the previous setup.
- Saved setups are machine-local, like the active colorscheme, so moving a monitor leaves `git status` clean and a fresh install starts with none.
