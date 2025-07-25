return {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "stevearc/dressing.nvim", -- optional for vim.ui.select
    },
    config = function()
        require("flutter-tools").setup({})
        vim.keymap.set("n", "<leader>Fr", ":FlutterRun<CR>", { silent = true, desc = "Flutter Run" })
    end,
}
