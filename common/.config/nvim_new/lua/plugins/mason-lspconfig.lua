return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        require("mason").setup({
            ui = {
                border = "single"
            }
        })
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "ts_ls" },
        })
    end,
}
