vim.o.background = "dark"
-- The background is left to kitty so terminal transparency shows through.
require("nordic").setup({
	transparent = { bg = true },
})
require("nordic").load()
