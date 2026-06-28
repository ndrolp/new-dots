vim.keymap.set("n", "<leader>fr", ":%s/", { silent = true, desc = "Find and replace all" })
vim.keymap.set("n", "<leader>fR", ":s/", { silent = true, desc = "Find and replace" })
vim.keymap.set("n", "<leader>dM", ":delmarks a-zA-Z<CR>")
local function go_mark(letter)
	vim.cmd("normal! `" .. letter)
end
local function del_mark(letter)
	vim.cmd("delmarks " .. letter)
end

-- a-z
for i = 97, 122 do
	local c = string.char(i)
	vim.keymap.set("n", "gm" .. c, function()
		go_mark(c)
	end)

	vim.keymap.set("n", "<leader>d" .. c, function()
		del_mark(c)
	end)
end

-- A-Z
for i = 65, 90 do
	local c = string.char(i)
	vim.keymap.set("n", "gm" .. c, function()
		go_mark(c)
	end)

	vim.keymap.set("n", "<leader>d" .. c, function()
		del_mark(c)
	end)
end
