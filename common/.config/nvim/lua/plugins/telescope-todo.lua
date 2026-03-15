return {
	{
		"ethanamaher/todo-telescope.nvim",

		enabled = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},

		config = function()
			require("todo-telescope").setup({
				-- uncomment lines to use custom options
				--
				-- define custom keyword list
				-- keywords = { "TODO", "FIXME", "NOTE", "REVIEW", }
				--
				-- case sensitivity
				-- case_sensitive = false,
				--
				-- max number of results in telescop picker
				-- max_results = 500
			})
		end,
	},
}
