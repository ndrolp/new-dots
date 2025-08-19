return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "catppuccin",
				-- section_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = " " },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
					NvimTree = {},
				},
				ignore_focus = {},
				always_divide_middle = false,
				globalstatus = true,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					{ "branch", icon = "" },
					{
						"diff",
						symbols = { added = " ", modified = " ", removed = " " }, -- Changes the symbols used by the diff.
					},
					{
						"diagnostics",
						sources = { "nvim_diagnostic", "coc" },
						sections = { "error", "warn", "info", "hint" },
						symbols = { error = "󰅙 ", warn = " ", info = " ", hint = "󰞋 " },
						colored = true, -- Displays diagnostics status in color if set to true.
						update_in_insert = false, -- Update diagnostics in insert mode.
						always_visible = false, -- Show diagnostics even if there are none.
					},
				},
				lualine_c = {
					{
						"filename",
						path = 0,
						symbols = {
							modified = "  ", -- Text to show when the file is modified.
							readonly = "  ", -- Text to show when the file is non-modifiable or readonly.
							unnamed = " No Name ", -- Text to show for unnamed buffers.
							newfile = " 󰝒 ", -- Text to show for newly created file before first write
						},
						{ test },
					},
				},
				lualine_x = {
					"lsp_status",
					"encoding",
				},
				lualine_y = { "progress", "searchcount" },
				lualine_z = { "filetype" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {
				lualine_a = {
					{
						"buffers",
						symbols = {
							modified = "  ", -- Text to show when the buffer is modified
							alternate_file = " 󱗼 ", -- Text to show to identify the alternate file
							directory = "  ", -- Text to show when the buffer is a directory
						},
					},
				},
				lualine_b = {},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {
					{
						"tabs",
						show_modified_status = false, -- Shows a symbol next to the tab name if the file has been modified.
						symbols = {
							modified = "[+]", -- Text to show when the file is modified.
						},
					},
				},
			},
			-- winbar = {
			--     -- lualine_a = {},
			-- },
			-- inactive_winbar = {},
			extensions = { "nvim-tree", "symbols-outline", "toggleterm" },
		})
	end,
}
