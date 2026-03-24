vim.keymap.set("n", "<leader>tn", ":tabedit%<CR>", { silent = true })
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", { silent = true })
for i = 1, 9 do
	vim.keymap.set("n", "<leader>t" .. i, i .. "gt", { silent = true })
end
