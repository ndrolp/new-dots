vim.o.background = "dark"
-- bloodmoon has no upstream nvim colorscheme: mini.base16 builds one from its palette.
require("mini.base16").setup({
	palette = {
		base00 = "#1a1012", -- background
		base01 = "#2a181b", -- surface
		base02 = "#3a2226", -- selection
		base03 = "#7d6662", -- comments
		base04 = "#bfa6a2", -- muted text
		base05 = "#f0e2dc", -- text
		base06 = "#f5ebe6",
		base07 = "#faf3f0",
		base08 = "#e0465a", -- accent
		base09 = "#f2804a", -- orange
		base0A = "#f0b45a", -- yellow
		base0B = "#8fb573", -- green
		base0C = "#e3a08a", -- rose tan, in place of cyan
		base0D = "#7f9fc9", -- blue
		base0E = "#c27ba0", -- purple
		base0F = "#ff3b3b", -- red
	},
})
vim.g.colors_name = "bloodmoon"
