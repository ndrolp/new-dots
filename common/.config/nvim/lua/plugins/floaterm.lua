return {
	"voldikss/vim-floaterm",
	config = function()
		vim.g.floaterm_width = 0.8
		vim.g.floaterm_height = 0.9
		vim.keymap.set({ "n", "t" }, "<C-j>", "<cmd>FloatermToggle<cr>", { desc = "Toggle floating terminal" })
	end,
}
