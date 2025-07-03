local func = require("vim.func")
return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            completions = { lsp = { enabled = true } },
            sign = {
                -- Turn on / off sign rendering.
                enabled = false,
                -- Applies to background of sign text.
                highlight = "RenderMarkdownSign",
            },
        },
    },
    {
        "epwalsh/obsidian.nvim",
        version = "*", -- recommended, use latest release instead of latest commit
        lazy = true,
        ft = "markdown",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("obsidian").setup({
                ui = { enable = false },
                workspaces = {
                    {
                        name = "personal",
                        path = "~/Documents/Vaults/Personal",
                    },
                },
            })

            vim.keymap.set("n", "<leader>on", ":ObsidianNew<CR>", { silent = true, desc = "New note" })
            vim.keymap.set("n", "<leader>ol", ":ObsidianLink<CR>", { silent = true, desc = "Obsidian Link" })
            vim.keymap.set("n", "<leader>of", ":ObsidianSearch<CR>", { silent = true, desc = "Obsidian Search" })
        end,
    },
}
