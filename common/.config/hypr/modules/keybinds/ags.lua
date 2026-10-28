local win = "SUPER"
local mainMod = "ALT"

hl.bind(
	win .. " + f",
	hl.dsp.exec_cmd("ags request toggle ndro-shell-wallpaper"),
	{ description = "Toggle AGS wallpaper picker" }
)
hl.bind(
	win .. " + c",
	hl.dsp.exec_cmd("ags request toggle ndro-shell-settings"),
	{ description = "Toggle AGS settings" }
)
hl.bind(
	mainMod .. " + w",
	hl.dsp.exec_cmd("ags request toggle ndro-shell-bar"),
	{ description = "Toggle AGS bar" }
)
hl.bind(
	mainMod .. " + SHIFT + g",
	hl.dsp.exec_cmd("ags request toggle ndro-shell-bar"),
	{ description = "Toggle AGS bar" }
)
