# The active colorscheme is machine-local

Applying a colorscheme used to rewrite about a dozen tracked files (symlinks, `theme.txt`, kitty's config, VS Code's settings), so every apply showed up as a diff and ended up in unrelated commits. We decided that the active colorscheme belongs to the machine, not the repo. Applying should leave `git status` clean. The repo records only the default colorscheme (`colorschemes/default.txt`).

## Consequences

- One gitignored symlink, `colorschemes/active`, names the active colorscheme. Every tracked colour link points through it, so those links never change.
- kitty includes a colour file through `active` instead of being rewritten by `kitten themes`.
- VS Code has no include mechanism, so a git clean filter (`.gitattributes`) stores `workbench.colorTheme` as the default colorscheme's VS Code theme no matter what the working copy says. The filter has to be registered in each clone's git config, which bootstrap does. Without it, applying shows up as a diff again. It never corrupts anything.
