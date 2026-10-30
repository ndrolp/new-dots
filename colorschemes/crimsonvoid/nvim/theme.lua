vim.o.background = "dark"
-- crimsonvoid has no upstream nvim colorscheme: mini.base16 builds one from its palette.
require("mini.base16").setup({
	palette = {
		base00 = "#000000", -- background
		base01 = "#1c1c1c", -- surface
		base02 = "#2a2a2a", -- selection
		base03 = "#5c5c5c", -- comments
		base04 = "#9a9a9a", -- muted text
		base05 = "#e6e6e6", -- text
		base06 = "#f0f0f0",
		base07 = "#fafafa",
		base08 = "#e01e37", -- accent
		base09 = "#e0874f", -- orange
		base0A = "#d9b45e", -- yellow
		base0B = "#8fb07a", -- green
		base0C = "#c9a0a0", -- dusty rose, in place of cyan
		base0D = "#7f9bc4", -- blue
		base0E = "#b07fb5", -- purple
		base0F = "#ff2a2a", -- red
	},
})
vim.g.colors_name = "crimsonvoid"
