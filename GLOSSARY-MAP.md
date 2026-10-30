# Glossary Map

## Contexts

- [Quickshell](./common/.config/quickshell/GLOSSARY.md): the desktop shell on Hyprland — bar, panels, desktop widgets and the settings panel

## Shared language

Terms that span every context.

**Colorscheme**:
A named set of colours (catppuccin, everforestdark…) applied to the whole desktop at once — Hyprland, Quickshell, the terminal, the editor — and switched with the colorscheme changer.
_Avoid_: Theme (on its own), palette

**Apply** (a colorscheme):
Make a colorscheme the active one everywhere at once: Hyprland, Quickshell, nvim, GTK, kitty, VS Code and rofi. Only applying changes which colorscheme is active.
_Avoid_: Switch, set (for this)

**Colorscheme preview**:
Showing a colorscheme on Hyprland and Quickshell only, without making it the active one; leaving the preview returns to the active colorscheme.
_Avoid_: Temporary theme, try-on

## Relationships

- **Quickshell → Hyprland**: Quickshell reads workspaces and monitors from Hyprland; monitor names are shared between the two.
