return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = {
		options = {
			parsers = {
				css = true, -- preset: enables names, hex, rgb, hsl, oklch
				tailwind = { enable = true },
				sass = { enable = true },
			},
			display = {
				mode = "virtualtext",
				virtualtext = { position = "before", char = "" },
			},
		},
	},
}
