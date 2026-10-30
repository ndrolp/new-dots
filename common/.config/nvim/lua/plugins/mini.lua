return {
	{
		"echasnovski/mini.comment",
		version = false,
		config = function()
			require("mini.comment").setup()
		end,
	},
	{
		"echasnovski/mini.icons",
		version = false,
		config = function()
			require("mini.icons").setup()
		end,
	},
	-- Builds the nvim colorscheme of colorschemes with no upstream one (bloodmoon).
	{
		"echasnovski/mini.base16",
		version = false,
		lazy = false,
		priority = 1000,
	},
}
