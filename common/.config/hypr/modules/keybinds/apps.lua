local mainMod = "ALT"
local win = "SUPER"

hl.bind(win .. " + e", hl.dsp.exec_cmd("nemo"))
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + m", hl.dsp.workspace.toggle_special({ workspace = "spotify" }))
