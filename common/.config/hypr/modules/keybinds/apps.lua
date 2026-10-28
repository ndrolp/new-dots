local mainMod = "ALT"
local win = "SUPER"

hl.bind(win .. " + e", hl.dsp.exec_cmd("nemo"), { description = "Open file manager" })
hl.bind(win .. " + w", hl.dsp.exec_cmd("google-chrome-stable"), { description = "Open web browser" })
hl.bind(mainMod .. " + m", hl.dsp.exec_cmd("spotify"), { description = "Launch Spotify" })
hl.bind(
	mainMod .. " + m",
	hl.dsp.workspace.toggle_special({ workspace = "spotify" }),
	{ description = "Toggle Spotify workspace" }
)
