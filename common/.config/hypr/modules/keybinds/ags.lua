local win = "SUPER"
local mainMod = "ALT"

hl.bind(win .. " + f", hl.dsp.exec_cmd("ags request toggle ndro-shell-wallpaper"))
hl.bind(win .. " + c", hl.dsp.exec_cmd("ags request toggle ndro-shell-settings"))
hl.bind(mainMod .. " + w", hl.dsp.exec_cmd("ags request toggle ndro-shell-bar"))
hl.bind(mainMod .. " + SHIFT + g", hl.dsp.exec_cmd("ags request toggle ndro-shell-bar"))
