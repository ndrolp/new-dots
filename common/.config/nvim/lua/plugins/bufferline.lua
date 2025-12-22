return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		local bufferline = require("bufferline")
		local mocha = require("catppuccin.palettes").get_palette("frappe")

		bufferline.setup({
			highlights = require("catppuccin.special.bufferline").get_theme(),
			options = {
				show_close_icon = false,
				show_buffer_close_icons = false,
				style_preset = bufferline.style_preset.minimal,
				separator_style = { "", "" },
				indicator = {
					-- icon = "▎", -- this should be omitted if indicator style is not 'icon'
					icon = "|", -- this should be omitted if indicator style is not 'icon'
					style = "icon",
				},
				tab_size = 10,
				diagnostics = "nvim_lsp",
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						text_align = "left",
						separator = true,
					},
				},
			},
		})
	end,
}
