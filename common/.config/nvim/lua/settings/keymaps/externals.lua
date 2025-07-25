local function run_lazygit()
	vim.fn.system("zellij run -f -c --height 90 --width 900 -x 0 -y 0 -- lazygit")
end

vim.keymap.set("n", "<leader>gl", run_lazygit, { silent = true, desc = "Launch Lazygit on Zellij" })
