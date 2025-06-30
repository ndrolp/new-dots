vim.wo.number = true
vim.wo.relativenumber = true
vim.lsp.inlay_hint.enable(true)

vim.o.timeoutlen = 300
vim.o.pumheight = 15
vim.o.scrolloff = 5
vim.o.ignorecase = true
vim.opt.encoding = "utf-8"

vim.opt.backspace = "2"
vim.opt.showcmd = true
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.o.termguicolors = true
vim.o.spell = false
vim.o.spelllang = "en_us"
vim.o.cmdheight = 0
vim.o.shell = "zsh"
vim.opt.conceallevel = 1
vim.o.laststatus = 3

local _border = "single"

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview

function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or _border
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

vim.diagnostic.config({
    float = {
        border = _border,
    },
})
