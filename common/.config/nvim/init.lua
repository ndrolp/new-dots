vim.g.mapleader = " "

require("settings.core.general")
require("settings.core.lsp")
require("settings.core.keymaps")
require("config.lazy")
require("settings.keymaps")
require("neovide")
require("settings.core.theme")

vim.lsp.config("qml-language-server", {
	cmd = { "qml-language-server" },
	filetypes = { "qml" },
	root_markers = { { "qmldir, shell.qml" }, ".git" },
})
vim.lsp.enable("qml-language-server")
