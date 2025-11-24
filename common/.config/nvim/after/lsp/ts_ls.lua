local hints = {
	includeInlayEnumMemberValueHints = true,
	includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
	includeInlayParameterNameHintsWhenArgumentMatchesName = true,
	includeInlayVariableTypeHints = false,
	-- includeInlayPropertyDeclarationTypeHints = true,
	-- includeInlayFunctionLikeReturnTypeHints = true,
	-- includeInlayFunctionParameterTypeHints = true,
}

return {

	on_attach = function(client, bufnr)
		-- Disable tsserver's formatting capabilities
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
	inlayHints = hints,
	settings = {
		inlayHints = hints,
		javascript = {
			inlayHints = hints,
		},
		typescript = {
			inlayHints = hints,
		},
		javascriptreact = {
			inlayHints = hints,
		},
		typescriptreact = {
			inlayHints = hints,
		},
	},
}
