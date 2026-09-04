return {
	"nvim-flutter/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim", -- optional for vim.ui.select
	},
	config = function()
		require("flutter-tools").setup({})
		vim.keymap.set("n", "<leader>FR", ":FlutterRun<CR>", { silent = true, desc = "Flutter Run" })
		vim.keymap.set("n", "<leader>Fr", ":FlutterRestart<CR>", { silent = true, desc = "Flutter Run" })
		vim.keymap.set("n", "<leader>Fh", ":FlutterReload<CR>", { silent = true, desc = "Flutter Reload" })
		vim.keymap.set("n", "<leader>Fd", ":FlutterDevices<CR>", { silent = true, desc = "Flutter Devices" })
		vim.keymap.set("n", "<leader>Fe", ":FlutterEmulators<CR>", { silent = true, desc = "Flutter Emulators" })
	end,
}
