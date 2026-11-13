# Glossary Map

## Contexts

- [Quickshell](./common/.config/quickshell/GLOSSARY.md): the desktop shell on Hyprland — bar, panels, desktop widgets and the settings panel

## Shared language

Terms that span every context.

**Colorscheme**:
A named set of colours (catppuccin, everforestdark…) applied to the whole desktop at once — Hyprland, Quickshell, the terminal, the editor — and switched with the colorscheme changer.
_Avoid_: Theme (on its own), palette

**Active colorscheme**:
The colorscheme a machine is currently showing. It belongs to that machine, not to the repo, so two machines can each have a different one.
_Avoid_: Current theme, selected theme

**Default colorscheme**:
The colorscheme a fresh install starts with, before anything has been applied. It is the only colorscheme choice the repo records.
_Avoid_: Base theme

**Shown colorscheme**:
The colorscheme Hyprland and Quickshell are showing right now. It is the active colorscheme, except during a colorscheme preview, when it is the one being previewed.
_Avoid_: Preview theme, displayed theme

**Apply** (a colorscheme):
Make a colorscheme the active one everywhere at once: Hyprland, Quickshell, nvim, GTK, kitty, VS Code and rofi. Only applying changes which colorscheme is active.
_Avoid_: Switch, set (for this)

**Colorscheme preview**:
Showing a colorscheme on Hyprland and Quickshell only, without making it the active one; leaving the preview returns to the active colorscheme.
_Avoid_: Temporary theme, try-on

**Terminal transparency**:
How see-through kitty's background is. It belongs to the terminal, not to any colorscheme, so applying a colorscheme never changes it.
_Avoid_: Theme opacity

**Centered layout**:
A way of arranging a workspace's windows for an ultrawide monitor: one main window sits in a middle column and every other window is tiled to its left or right. A window that is alone fills the whole width; once another window opens, the main window takes the middle and keeps that place when focus moves to a side window; only an explicit swap changes it. New windows open at the sides. It is turned on and off one workspace at a time with a keybind, on any monitor; turning it off gives the workspace back the layout it had before. Nothing remembers it: restarting Hyprland returns every workspace to its usual layout.
_Avoid_: Profile, layout profile, ultrawide mode

## Relationships

- **Quickshell → Hyprland**: Quickshell reads workspaces and monitors from Hyprland; monitor names are shared between the two.
