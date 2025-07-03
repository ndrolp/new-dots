return {
    {

        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                    live_grep = {
                        hidden = true,
                    },
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({
                            -- even more opts
                        }),
                    },
                },
            })
            require("telescope").load_extension("ui-select")
            vim.keymap.set(
                "n",
                "<C-p>",
                ":Telescope find_files theme=dropdown<CR>",
                { silent = true, desc = "Find Files" }
            )
        end,
        keys = {
            { "<leader>ff", ":Telescope find_files theme=dropdown<CR>", desc = "Find files" },
            { "<leader>fg", ":Telescope live_grep<CR>",                 desc = "Find grep" },
        },
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
    },
}
