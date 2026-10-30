vim.o.background = "dark"
-- nordic.nvim shares crimsonvoid's River Bed greys; its reds become Coral Tree. The background is left
-- to kitty so terminal transparency shows through.
require("nordic").setup({
	transparent = { bg = true },
	on_palette = function(palette)
		palette.black0 = "#0F1115"
		palette.black1 = "#0F1115"
		palette.red = { base = "#A86B6B", bright = "#C08585", dim = "#8F5A5A" }
	end,
})
require("nordic").load()
