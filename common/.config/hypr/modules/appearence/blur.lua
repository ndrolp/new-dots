-- Blur's size comes from the Windows section of the shell's settings: modules/appearence/windows.lua
hl.config({
	decoration = {
		blur = {
			enabled = true,
			passes = 3,
			noise = 0.09,
			vibrancy = 0.1696,
		},
	},
})
