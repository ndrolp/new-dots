vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", {})
vim.keymap.set("n", "<leader>vs", ":vs<CR>", {})
vim.keymap.set("n", "<leader>vv", ":split<CR>", {})
vim.keymap.set("n", "<leader>h", ":noh<CR>", { desc = "Hide highlight" })

vim.keymap.set("n", "<leader>bq", ":bd<CR>", { desc = "Close the current buffer", silent = true })
vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Go to next buffer", silent = true })
vim.keymap.set("n", "<leader>bb", ":bprevious<CR>", { desc = "Go to previus buffer", silent = true })
vim.keymap.set("n", "<C-l>", ":bnext<CR>", { desc = "Go to next buffer", silent = true })
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", { desc = "Go to previus buffer", silent = true })
vim.keymap.set("n", "<leader>ba", ":BDelete all<CR>", { desc = "Close all buffers", silent = true })
vim.keymap.set("n", "<leader>bh", ":BDelete hidden<CR>", { desc = "Close non visible buffers", silent = true })
vim.keymap.set("n", "<leader>bo", ":BDelete other<CR>", { desc = "Close all buffers except current", silent = true })

vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- vim.api.nvim_set_keymap("n", "<leader>R", ":source $MYVIMRC", { noremap = true, silent = true })
local inlay_hints_enabled = true

function ToggleInlayHints()
    inlay_hints_enabled = not inlay_hints_enabled
    vim.lsp.inlay_hint.enable(inlay_hints_enabled)
end

-- Example keymap: <leader>ih to toggle inlay hints
vim.keymap.set("n", "<leader>li", ToggleInlayHints, { desc = "Toggle Inlay Hints" })
