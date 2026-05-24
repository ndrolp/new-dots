return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},

		opts = {
			adapters = {
				http = {
					lmstudio = function()
						return require("codecompanion.adapters").extend("openai_compatible", {
							env = {
								url = "http://localhost:1234",
								api_key = "dummy",
								chat_url = "/v1/chat/completions",
							},

							schema = {
								model = {
									default = "google/gemma-4-e4b",
								},
							},
						})
					end,
				},
			},

			interactions = {
				chat = {
					adapter = "lmstudio",
				},

				inline = {
					adapter = "lmstudio",
				},

				cmd = {
					adapter = "lmstudio",
				},
			},

			opts = {
				log_level = "DEBUG",
			},
		},
	},
	{
		"Kurama622/llm.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},

		cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },

		config = function()
			require("llm").setup({
				url = "http://localhost:1234/v1/chat/completions",

				model = "google/gemma-4-e4b",

				api_type = "openai",

				timeout = 1000,
				max_tokens = 1024,

				temperature = 0.2,
				top_p = 0.95,
			})
		end,
	},
}
